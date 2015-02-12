//
//  CSStorage.m
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import "CSStorage.h"
#import <sqlite3.h>
#import <pthread.h>
#import "CSDataPoint.h"
#import "CSSettings.h"

static const int DEFAULT_DB_LOCK_TIMEOUT = 200; //when the database is locked, keep retrying until this timeout elapses. In milliseconds.
static const double DB_WRITEBACK_TIMEINTERVAL = 10 * 60;// interval between writing back to storage. Saves power and flash
static const size_t BUFFER_NR_ROWS = 1000;
static const size_t BUFFER_WRITEBACK_THRESHOLD = 1000;
static const long MAX_DB_SIZE = 100*1000*1000; // 100mb
static const char *SALT = "I3oL@YeQo8!pU3qe";

//static const long MINIMUM_FREE_SPACE = 1000*1000*20; //20mb




@implementation CSStorage {
    NSString* dbPath;
    sqlite3* db;
    pthread_mutex_t dbMutex;
    long long lastDataPointid;
    long long lastRowIdInStorage;
    BOOL isEncrypted;
}

#pragma mark - initialization
- (id) initWithPath:(NSString*) databaseFilePath {
    if (self) {
        dbPath = databaseFilePath;
        pthread_mutex_init(&dbMutex, NULL);
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath] == YES) {
            //ensure encryption attribute is set. Needed when the file was created by an earlier version that didn't set this.
            NSError* error = nil;
            BOOL succeed = [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication} ofItemAtPath:dbPath error:&error];
            if (succeed == NO) {
                NSLog(@"Unable to use iOS data protection for the database. Error %@", [error localizedDescription]);
            }
            
        } else {
            //create file with encryption attribute set
            BOOL succeed = [[NSFileManager defaultManager] createFileAtPath:dbPath contents:nil attributes:@{NSFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication}];
            if (succeed == NO) {
                NSLog(@"Unable to create the database file using iOS data protection");
            }
        }


        [self databaseInit];
        
        // setup encryption
        BOOL shouldUseEncryption = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingLocalStorageEncryption] isEqualToString:kCSSettingYES];
        [self changeStorageEncryptionEnabled:shouldUseEncryption];

        //set timer to store buffered data
        [NSTimer scheduledTimerWithTimeInterval:DB_WRITEBACK_TIMEINTERVAL target:self selector:@selector(writeDbToFile) userInfo:nil repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeGeneral] object:nil];
    }
    
    return self;
}

- (void) databaseInit {
    //Not sure sqlite might use a lot of memory, try to limit this somewhat.
    sqlite3_soft_heap_limit64(10*1024*1024);
    
    //Note: leaking errMsg on error
    char *errMsg = NULL;
    //open the database
    pthread_mutex_lock(&dbMutex);
    
    if (sqlite3_open_v2([dbPath UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error opening database" reason:@"Couldn't open database file" userInfo:nil];
    }
    
    // check if we are using encryption
    if (sqlite3_exec(db, (const char*) "SELECT count(*) FROM sqlite_master;", NULL, NULL, NULL) == SQLITE_OK) {
        isEncrypted = NO;
    } else {
        // maybe it's encrypted, close and reopen the file
        sqlite3_close_v2(db);
        if (sqlite3_open_v2([dbPath UTF8String], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {
            pthread_mutex_unlock(&dbMutex);
            @throw [NSException exceptionWithName:@"DB error opening database" reason:@"Couldn't open database file" userInfo:nil];
        }
        
        const char *key = [[self getEncryptionKey] UTF8String];
        sqlite3_key(db, key, (int)strlen(key));
        
        errMsg = NULL;
        if (sqlite3_exec(db, (const char*) "SELECT count(*) FROM sqlite_master;", NULL, NULL, &errMsg) == SQLITE_OK) {
            isEncrypted = YES;
        } else {
            NSLog(@"Failed to open file with key reason:%s", errMsg);
            // ups! something wrong. maybe the database is corrupt. Let's start with clean database and start over
            sqlite3_close_v2(db);
            [CSStorage deleteFileWithPath:dbPath error:nil];
            
            pthread_mutex_unlock(&dbMutex);
            [self databaseInit];
            
            return;
        }
    }
    
    //setup
    sqlite3_busy_timeout(db, DEFAULT_DB_LOCK_TIMEOUT);
    
    //create in memory database. This database is used as a buffer before storing data. It is buffered to minimise power usage due to io.
    const char *buffer_stmt = "ATTACH DATABASE ':memory:' AS buf";
    if (sqlite3_exec(db, buffer_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error attaching memory buffer" reason:@"Couldn't create buffer" userInfo:nil];
    }
    
    // get the current page size.
    const char *sql_stmt = [[NSString stringWithFormat:@"PRAGMA page_size"] UTF8String];
    sqlite3_stmt* stmt_ps;
    long long page_size = 1;
    NSInteger ret = sqlite3_prepare_v2(db, sql_stmt, -1, &stmt_ps, NULL);
    if (ret == SQLITE_OK) {
        while (sqlite3_step(stmt_ps) == SQLITE_ROW) {
            page_size = sqlite3_column_int64(stmt_ps, 0);
        }
        sqlite3_finalize(stmt_ps);
    } else {
        sqlite3_finalize(stmt_ps);
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error getting page size" reason:@"Couldn't get page size" userInfo:nil];

    }
    
    long max_page_count = MAX_DB_SIZE / page_size;
    
    NSLog(@"Max db size: %li, Page size: %lli, Max page count: %li", MAX_DB_SIZE, page_size, max_page_count);
    
    // Limit the number of pages. When full, an INSERT will return SQLITE_FULL.
    const char *sql_stmt_max_pages = [[NSString stringWithFormat:@"PRAGMA max_page_count = %li", max_page_count] UTF8String];
    if (sqlite3_exec(db, sql_stmt_max_pages, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error setting max_page_count" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    
    //create the table
    const char *sql_stmt_create1 = "CREATE TABLE IF NOT EXISTS data (ID INTEGER PRIMARY KEY, timestamp real, sensor_name TEXT, sensor_description TEXT, device_type TEXT, device TEXT, data_type TEXT, value TEXT)";

    if (sqlite3_exec(db, sql_stmt_create1, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error creating table data" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }

    //create table buffer
    const char *create_sql_stmt = "CREATE TABLE IF NOT EXISTS buf.data (ID INTEGER PRIMARY KEY, timestamp real, sensor_name TEXT, sensor_description TEXT, device_type TEXT, device TEXT, data_type TEXT, value TEXT)";
    
    if (sqlite3_exec(db, create_sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error creating table buf.data" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    
    //create indexes
    //create index on timestamp as most data functions request data in a range
    const char *index5_stmt = "create index IF NOT EXISTS timestamp_index on data(timestamp)";
    if (sqlite3_exec(db, index5_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error creating index on data" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }

    //same for in memory data
    const char *index_stmt = "create index IF NOT EXISTS buf.timestamp_index on data(timestamp)";
    if (sqlite3_exec(db, index_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error creating index on buf.data" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    
    //update lastRowIdInStorage
    const char* queryRowId = "SELECT MAX(id) from data";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db, queryRowId, -1, &stmt, NULL) == SQLITE_OK) {
        NSInteger ret = sqlite3_step(stmt);
        if (ret == SQLITE_ROW) {
            lastDataPointid = sqlite3_column_int64(stmt, 0);
        } else {
            
            NSLog(@"Database error: getting max rowid didn't return SQLITE_ROW");
        }
        sqlite3_finalize(stmt);
    } else {
        sqlite3_finalize(stmt);
        @throw [NSException exceptionWithName:@"DB error getting last row id" reason:[NSString stringWithCString:sqlite3_errmsg(db) encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    

    lastRowIdInStorage = lastDataPointid;
    
    //Create table for sensor descriptions.
    //create the table
    const char *sql_stmt_sensor_descriptions = "CREATE TABLE IF NOT EXISTS sensor_descriptions (sensor_name TEXT, sensor_description TEXT, device_type TEXT, device TEXT, json_description TEXT, PRIMARY KEY (sensor_name, sensor_description, device_type, device))";
    
    if (sqlite3_exec(db, sql_stmt_sensor_descriptions, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error creating table sensor_descriptions" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    
    pthread_mutex_unlock(&dbMutex);
    
    NSLog(@"Database at '%@' initialized", dbPath);
}

#pragma mark - store

/**
 * Store a new sensor data point in the buffer. Note that if the db is full, 20% of rows will be removed and the function is called again.
 * @param sensor Name of the sensor to store the value in
 * @param description Description of the sensor
 * @param deviceType Device type text
 * @param device String identifier of the device
 * @param dataType Don't know
 * @param value Can be a JSON string or just a string representation of the value to store
 * @param timestamp In seconds since 1970 representing when the value occured
 */
- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp {
    //insert into db
    const char *sql_stmt = [[NSString stringWithFormat:@"INSERT INTO buf.data (id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value) VALUES (%lli, %f, %@, %@, %@, %@, %@, %@);", ++lastDataPointid , timestamp, quotedAndEncodedString(sensor), quotedAndEncodedString(description), quotedAndEncodedString(deviceType),
                             quotedAndEncodedString(device), quotedAndEncodedString(dataType), quotedAndEncodedString(value)] UTF8String];

    int ret;
    pthread_mutex_lock(&dbMutex);
    ret = sqlite3_exec(db, sql_stmt, NULL, NULL, NULL);
    
    if (ret == SQLITE_FULL) {
        pthread_mutex_unlock(&dbMutex);
        NSLog(@"Database is full");
        
        //remove lines
        [self trimLocalStorageTo:0.8]; //trim to 80% of rows by removing 20% of oldest rows
        
        //and retry
        [self storeSensor:sensor description:description deviceType:deviceType device:device dataType:dataType value:value timestamp:timestamp];
    } else if (ret != SQLITE_OK) {
        NSLog(@"Database Error inserting sensor data into buffer: %s", sqlite3_errmsg(db));
        //@throw [NSException exceptionWithName:@"DB error" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    pthread_mutex_unlock(&dbMutex);
    
    if (lastDataPointid - lastRowIdInStorage >= BUFFER_WRITEBACK_THRESHOLD) {
        [self flush];
    }
}

#pragma mark - retrieve

- (NSArray*) getSensorDataPointsFromId:(long long) start limit:(size_t) limit{
    NSMutableArray* results = [NSMutableArray new];

    /* Query data table and buffer. We need the limits inside the query to avoid reading in the whole table. Subqueries are needed to get the limits inside */
    const char* query = [[NSString stringWithFormat: @"SELECT * FROM (SELECT id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value FROM buf.data where id >= %lli limit %zu) UNION SELECT * FROM  (SELECT id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value FROM data where id >= %lli limit %zu) order by id LIMIT %zu", start, limit, start, limit, limit] UTF8String];
    sqlite3_stmt* stmt;
    pthread_mutex_lock(&dbMutex);
    NSInteger ret = sqlite3_prepare_v2(db, query, -1, &stmt, NULL);
    if (ret == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            CSDataPoint* p = [[CSDataPoint alloc] init];
            p.dataPointID = sqlite3_column_int64(stmt, 0);
            p.timestamp = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmt, 1)];
            p.sensor = decodedString((const char*)sqlite3_column_text(stmt, 2));
            p.sensorDescription = decodedString((const char*)sqlite3_column_text(stmt, 3));
            p.deviceType = decodedString((const char*)sqlite3_column_text(stmt, 4));
            p.deviceUUID = decodedString((const char*)sqlite3_column_text(stmt, 5));
            p.dataType = decodedString((const char*)sqlite3_column_text(stmt, 6));
            p.timeValue = decodedString((const char*)sqlite3_column_text(stmt, 7));
            
            [results addObject:p];
        }
    } else if (ret != SQLITE_NOTFOUND) {
        NSLog(@"database error. getSensorDataPointsFromId: %li.", (long)ret);
    }
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&dbMutex);
    
    return results;
}

/** Retrieve all the sensor data stored in the database between a certain time interval.
 * @param name The name of the sensor to get the data from
 * @param startDate The date and time at which to start looking for datapoints
 * @param endDate The date and time at which to stop looking for datapoints
 * @return an array of values, each value is a dictonary that descirbes the data point
 */
- (NSArray*) getDataFromSensor: (NSString*) name from: (NSDate*) startDate to: (NSDate*) endDate {
    
    NSMutableArray* results = [[NSMutableArray alloc] init];
    
    //make database query (SORT by timestamp) for buffer and main hd db
    const char* query = [[NSString stringWithFormat:@"SELECT * FROM (SELECT timestamp, value FROM buf.data WHERE sensor_name = '%@' AND timestamp >= %f AND timestamp < %f UNION SELECT timestamp, value FROM data WHERE sensor_name = '%@' AND timestamp >= %f AND timestamp < %f) ORDER BY timestamp ASC", name, [startDate timeIntervalSince1970], [endDate timeIntervalSince1970], name, [startDate timeIntervalSince1970], [endDate timeIntervalSince1970]] UTF8String];
    
    //NSLog(@"Executing query: %s", query);
    
    sqlite3_stmt* stmt;
    pthread_mutex_lock(&dbMutex);
    NSInteger ret = sqlite3_prepare_v2(db, query, -1, &stmt, NULL);
    if (ret == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            
            NSDate* timestamp = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmt, 0)];
            NSString* jsonString = decodedString((const char*)sqlite3_column_text(stmt, 1));
            
            //for each row, make dictionary with time value pair of timestamp and value
            [results addObject: [self makeDictionaryFromDate: timestamp andString: jsonString]];
        }
    } else if (ret != SQLITE_NOTFOUND) {
        NSLog(@"database error. getDataFromSensor: %li errmsg: %s.", (long)ret, sqlite3_errmsg(db));
        ;
    }
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&dbMutex);
    
    //return array of dictionaries
    return results;
}

- (NSDictionary*) makeDictionaryFromDate: (NSDate*) timestamp andString: (NSString*) value {
    
    NSError* error;
    
    //try to convert to json data and test if there is a valid result
    NSData* jsonData = [value dataUsingEncoding:NSUTF8StringEncoding];
    id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if([NSJSONSerialization isValidJSONObject:json]) {
        if(json) { // store as JSON object
            return @{@"timestamp":timestamp, @"value":json};
        } else {
            NSLog(@"There seems to be a problem with the JSON formatting of %@ because %@", jsonData, [error description]);
            return nil;
        }
    } else { // just use the string as value because the string is not in a valid JSON format
        return @{@"timestamp":timestamp, @"value":value};
    }
}


#pragma mark - delete

- (void) removeDataBeforeId:(long long) rowId {
    [self removeDataTillId:rowId table:@"buf.data"];
    [self removeDataTillId:rowId table:@"data"];
    
}

/**
 * Removes all data from before a certain date from buffer and main data store
 * @param: dateThreshold The date which marks the threshold, all data older than (from before) the date will be removed
 */
- (void) removeDataBeforeTime:(NSDate *) dateThreshold {
    [self removeDataBeforeTime:dateThreshold fromTable:@"buf.data"];
    [self removeDataBeforeTime:dateThreshold fromTable:@"data"];
}


/**
 * Removes all data from before a certain date
 * @param: table Table that data will be removed from
 * @param: dateThreshold The date which marks the threshold, all data older (from before) the date will be removed
 */
- (void) removeDataBeforeTime:(NSDate *) dateThreshold fromTable: (NSString*) table {

    const char* query = [[NSString stringWithFormat:@"DELETE FROM %@ where timestamp < %lli", table, (long long)([dateThreshold timeIntervalSince1970])] UTF8String];
    pthread_mutex_lock(&dbMutex);
    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"removeDataTillId failure: %s", sqlite3_errmsg(db));
    }
    pthread_mutex_unlock(&dbMutex);
    
}

/**
 * Removes all data from before a certain row id
 * @param: table Table that data will be removed from
 * @param: rowId The id of the highest numbered row that will be removed, together with all rows with lower numbered ids */
- (void) removeDataTillId:(long long) rowId table:(NSString*) table {
    const char* query = [[NSString stringWithFormat:@"DELETE FROM %@ where id <= %lli", table, rowId] UTF8String];
    pthread_mutex_lock(&dbMutex);
    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"removeDataTillId failure: %s", sqlite3_errmsg(db));
    }
    pthread_mutex_unlock(&dbMutex);
}


#pragma mark - maintenance

/**
 * Function to write the buffer to the db file. Checks if the db is full, if so, removes 20% of the rows (oldest rows) and makes a new attempt to write the db to file.
 */
- (void) writeDbToFile {

  //  NSLog(@"Writing data buffer to file");
    
   const char* query = [[NSString stringWithFormat:@"insert into data (id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value) select id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value from buf.data as bv where id > %lli", lastRowIdInStorage] UTF8String];
    pthread_mutex_lock(&dbMutex);
    char* errMsg;
    BOOL succeed = YES;
    
    int attemptCount = 0;
    int queryResult;
    while ((queryResult = sqlite3_exec(db, query, NULL, NULL, &errMsg)) == SQLITE_FULL) {
    
        NSLog(@"Database is full: %s", errMsg);
        
        //remove lines
        pthread_mutex_unlock(&dbMutex);
        [self trimLocalStorageTo:0.8]; //trim to 80% of rows by removing 20% of oldest rows
        pthread_mutex_lock(&dbMutex);
        
        //and retry if less than 20 attempts have been made
        if( attemptCount < 20) {
            attemptCount++;
        } else {
            NSLog(@"More than 20 attempts have been made to clean up the db and write buffer to file but this did not succeed yet. DB is still full. Something went horribly wrong.");
            break;
        }
    }
    
    if (queryResult != SQLITE_OK) {
        NSLog(@"writeDbToFile DB failure: %s", errMsg);
        succeed = NO;
    }
    
    if (errMsg)
        sqlite3_free(errMsg);

    if (succeed == NO) {
            pthread_mutex_unlock(&dbMutex);
            return;
    }

    //update lastRowIdInStorage
    const char* queryRowId = "SELECT MAX(id) from data";
    sqlite3_stmt* stmt;
    if (sqlite3_prepare_v2(db, queryRowId, -1, &stmt, NULL) == SQLITE_OK) {
        NSInteger ret = sqlite3_step(stmt);
        if (ret == SQLITE_ROW) {
            lastRowIdInStorage = sqlite3_column_int64(stmt, 0);
        } else {
            NSLog(@"Database error: getting max rowid didn't return SQLITE_ROW");
        }
    } else {
        NSLog(@"Database error: getting max rowid");
    }
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&dbMutex);
    
    //trim the buffer
    [self trimBufferToSize:BUFFER_NR_ROWS];
}

/**
 * Checks if database is smaller than numberOfBytes and if not, reduces DB size to something that is numberOfBytes or 90% of free space plus what we already use by removing oldest rows (with the lowest IDs) from the database
 * @param numberOfBytes number of bytes that the local storage can be on the disk
 */
- (void) trimLocalStorageTo: (double) percentToKeep {

    //calculate number of rows to keep
    long nRowsToKeep = percentToKeep * [self getNumberOfRowsInTable:@"data"];
        
    NSLog(@"Trimming local storage to keep only %f percent (or %li datapoints)", percentToKeep, nRowsToKeep);
        
    //remove oldest rows while keeping nRowsToKeep
    [self trimLocalStorageToRowsToKeep:nRowsToKeep];

}


/**
 * Get the total number of rows in a database
 * @param dbName SQL Identifier of the database name
 */

- (long) getNumberOfRowsInTable:(NSString *) table {
    
    const char* queryRowId = [[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", table] UTF8String];
    sqlite3_stmt* stmt;
    pthread_mutex_lock(&dbMutex);
    if (sqlite3_prepare_v2(db, queryRowId, -1, &stmt, NULL) == SQLITE_OK) {
        NSInteger ret = sqlite3_step(stmt);
        if (ret == SQLITE_ROW) {
            long nRows = sqlite3_column_int(stmt, 0);
            pthread_mutex_unlock(&dbMutex);
            sqlite3_finalize(stmt);
            return  nRows;
        } else {
            NSLog(@"Database error: getting count of rows didn't return SQLITE_ROW");
            sqlite3_finalize(stmt);
            pthread_mutex_unlock(&dbMutex);
            return 0;
        }
    } else {
        sqlite3_finalize(stmt);
        pthread_mutex_unlock(&dbMutex);
        NSLog(@"Database error: getting count of rows");
        return 0;
    }

}

/*
 * Returns the size of the local storage database in bytes
 */
- (NSNumber *) getDbSize {
    NSError *error = nil;
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:dbPath error:&error];
   // NSLog(@"Local database store size: %@ bytes", [fileAttributes objectForKey:NSFileSize]);
    
    return [fileAttributes objectForKey:NSFileSize];
}

/*
 * Returns the number of bytes of free space on the disk
 */

- (NSNumber *) getFreeSpaceOnDisk {
    NSError *error = nil;
    NSDictionary *fileSystemAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:dbPath error:&error];
    //NSLog(@"Free space on file system: %@ bytes", [fileSystemAttributes objectForKey:NSFileSystemFreeSize]);
    
    return [fileSystemAttributes objectForKey:NSFileSystemFreeSize];
}


- (void) cleanBuffer {
    //delete from the buffer all persisted rows
    [self removeDataTillId:lastRowIdInStorage table:@"buf.data"];

}

- (void) trimBufferToSize:(size_t) nr {
    //delete from the buffer all persisted rows, but keep 'nr' points.
    //Note that the actual size of the buffer might end up to be different from 'nr'. it's a cache, so we're a bit lenient with that.
    //e.g. when there are unpersisted rows, this function will NEVER delete those
    long long nrInMem = lastDataPointid - lastRowIdInStorage;
    long long deleteThreshold = lastRowIdInStorage - MAX(nr - nrInMem, 0);
    [self removeDataTillId:deleteThreshold table:@"buf.data"];

}

/**
 * Delete all rows of the database except the nrToKeep most recent rows based on id field
 * @param nrToKeep Number of most recent rows to keep (oldest rows will be removed first)
 *
 */
- (void) trimLocalStorageToRowsToKeep:(size_t) nrToKeep {
    //delete from the local storage all persisted rows, but keep 'nrToKeep' points.
    //Note that the actual size of the local storage might end up to be different from 'nr'
    //e.g. when there are unpersisted rows, this function will NEVER delete those
    long long deleteThreshold = lastRowIdInStorage - nrToKeep;
    [self removeDataTillId:deleteThreshold table:@"data"];
}

- (void) flush {
    [self writeDbToFile];
    [self cleanBuffer];
}

#pragma mark - status
- (long long) getLastDataPointId {
    return self->lastDataPointid;
}

#pragma mark - sensor_descriptions
- (void) storeSensorDescription:(NSString*) jsonDescription forSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device {
    //insert into db
    const char *sql_stmt = [[NSString stringWithFormat:@"INSERT OR REPLACE INTO sensor_descriptions (sensor_name, sensor_description, device_type, device, json_description) VALUES (%@, %@, %@, %@, %@);",
                             quotedAndEncodedString(sensor), quotedAndEncodedString(description), quotedAndEncodedString(deviceType), quotedAndEncodedString(device), quotedAndEncodedString(jsonDescription)] UTF8String];
    
    int ret;
    pthread_mutex_lock(&dbMutex);
    ret = sqlite3_exec(db, sql_stmt, NULL, NULL, NULL);
    
    if (ret != SQLITE_OK) {
        NSLog(@"Database Error inserting sensor description into sensor_descriptions: %s", sqlite3_errmsg(db));
        //@throw [NSException exceptionWithName:@"DB error" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    pthread_mutex_unlock(&dbMutex);
}

- (NSString*) getSensorDescriptionForSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device {
    
    NSString* jsonDescription = nil;
    const char* query = [[NSString stringWithFormat:@"SELECT json_description FROM sensor_descriptions where sensor_name = %@ AND sensor_description = %@ AND device_type = %@ AND device = %@ limit 1",
                          quotedAndEncodedString(sensor), quotedAndEncodedString(description), quotedAndEncodedString(deviceType), quotedAndEncodedString(device)] UTF8String];
    sqlite3_stmt* stmt;
    pthread_mutex_lock(&dbMutex);
    NSInteger ret = sqlite3_prepare_v2(db, query, -1, &stmt, NULL);
    if (ret == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            jsonDescription = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 0)];
            break;
        }
    } else if (ret != SQLITE_NOTFOUND) {
    }
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&dbMutex);
    
    
    return jsonDescription;
}

static NSString* quotedAndEncodedString(NSString* input) {
    if (input == nil) {
        return nil;
    }
    return [NSString stringWithFormat:@"\'%@\'",[input stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
}

static NSString* decodedString(const char* encoded) {
    if (encoded == nil) {
        return nil;
    }
    return [[NSString stringWithUTF8String:encoded] stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
}

#pragma mark - database encryption
/**
 * Get encryption key from settings, if not found, use device uuid
 */
- (NSString*) getEncryptionKey {
    NSString* key = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingLocalStorageEncryptionKey];
    
    // use uuid
    if (key == nil) {
        key = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] stringByAppendingFormat:@"%s", SALT];
        
        if (key == nil) {
            @throw [NSException exceptionWithName:@"DB error generating key" reason:@"Couldn't get device uuid" userInfo:nil];
        }
    }
    
    return key;
}

- (void) changeStorageEncryptionEnabled:(BOOL) enable {
    if (enable == isEncrypted) { // already same, nothing todo
        return;
    } else {

        NSString *tempDbPath = [dbPath stringByAppendingString:@"-temp.db"];
        [CSStorage deleteFileWithPath:tempDbPath error:nil];

        @try {
            [self flush];
            pthread_mutex_lock(&dbMutex);
            
            // convert database
            // attach temp database
            char *errMsg = NULL;
            NSString *query;
            const char *key;
            if (enable) { // plain -> encrypted
                key = [[self getEncryptionKey] UTF8String];
            } else { // encrypted -> plain
                key = "";
            }

            query =  [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS tempDB KEY '%s'", tempDbPath, key];
            if (sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                pthread_mutex_unlock(&dbMutex);
                @throw [NSException exceptionWithName:@"Attaching temporary database error" reason:[NSString stringWithUTF8String:errMsg] userInfo:nil];
                
            }
        
            // export databse
            query = @"SELECT sqlcipher_export('tempDB')";
            if (sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                pthread_mutex_unlock(&dbMutex);
                @throw [NSException exceptionWithName:@"Exporting database error" reason:[NSString stringWithUTF8String:errMsg] userInfo:nil];
                
            }
            
            // detach temp database
            query = @"DETACH DATABASE tempDB";
            int ret = sqlite3_exec(db, [query UTF8String], NULL, NULL, &errMsg);
            if (ret != SQLITE_OK) {
                pthread_mutex_unlock(&dbMutex);
                @throw [NSException exceptionWithName:@"Detatching tempDB error" reason:[NSString stringWithUTF8String:errMsg] userInfo:nil];
                
            }
            
            // rename temp database to primary
            sqlite3_close_v2(db);
            
            NSFileManager *filemgr = [NSFileManager defaultManager];
            
            NSURL *oldPath = [NSURL fileURLWithPath:tempDbPath];
            NSURL *newPath= [NSURL fileURLWithPath:dbPath];
            
            NSError* err = nil;
            [CSStorage deleteFileWithPath:dbPath error:&err];
            
            if (err != nil ) {
                @throw [NSException exceptionWithName:@"Removing main fail error" reason:err.description userInfo:nil];
            }
            
            if (![filemgr moveItemAtURL: oldPath toURL: newPath error: &err]) {
                NSLog(@"Moving temporary file error reason: %@", err.description);
            }

            pthread_mutex_unlock(&dbMutex);

            
            // reopen database
            [self databaseInit];
            
            if (enable) { // plain -> encrypted
                NSLog(@"SenseLibrary Finished encrypting database %@", dbPath);
            } else { // encrypted -> plain
                NSLog(@"SenseLibrary Finished decrypting database %@", dbPath);
            }
        }
        @catch (NSException *exception) {
            NSLog(@"Encrypting database error: %@ reason: %@", exception.name, exception.reason);
        }
        @finally {
            [CSStorage deleteFileWithPath:tempDbPath error:nil];
        }
    }

}

#pragma mark auxilary function
+(void) deleteFileWithPath:(NSString*) path error:(NSError**) err {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    err = nil;
    [fm removeItemAtPath:[url path] error:err];
}



- (void) settingChanged: (NSNotification*) notification  {
    @try {
        CSSetting* setting = notification.object;
        NSLog(@"Local Storage setting %@ changed to %@.", setting.name, setting.value);
        
        if ([setting.name isEqualToString:kCSGeneralSettingLocalStorageEncryption]) {
            [self changeStorageEncryptionEnabled:[setting.value isEqualToString:kCSSettingYES]];
        }
    }
    @catch (NSException * e) {
        NSLog(@"LocationSensor: Exception thrown while applying location settings: %@", e);
    }
}


@end
