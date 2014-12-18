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

static const int DEFAULT_DB_LOCK_TIMEOUT = 200; //when the database is locked, keep retrying until this timeout elapses. In milliseconds.
static const double DB_WRITEBACK_TIMEINTERVAL = 10 * 60;// interval between writing back to storage. Saves power and flash
static const size_t BUFFER_NR_ROWS = 1000;
static const size_t BUFFER_WRITEBACK_THRESHOLD = 1000;
//static const int MAX_DB_SIZE_ON_DISK = 1000*1000*500; // 500mb
static const int MAX_DB_SIZE_ON_DISK = 1000*50; // 50kb


@implementation CSStorage {
    NSString* dbPath;
    sqlite3* db;
    pthread_mutex_t dbMutex;
    long long lastDataPointid;
    long long lastRowIdInStorage;
}

#pragma mark - initialization
- (id) initWithPath:(NSString*) databaseFilePath {
    if (self) {
        dbPath = databaseFilePath;
        pthread_mutex_init(&dbMutex, NULL);
        [self databaseInit];

        //set timer to store buffered data
        [NSTimer scheduledTimerWithTimeInterval:DB_WRITEBACK_TIMEINTERVAL target:self selector:@selector(writeDbToFile) userInfo:nil repeats:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flush) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
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
        //ai, we need to recover
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error opening database" reason:@"Couldn't open database file" userInfo:nil];

    }
    
    //setup
    sqlite3_busy_timeout(db, DEFAULT_DB_LOCK_TIMEOUT);
    
    //create in memory database. This database is used as a buffer before storing data. It is buffered to minimise power usage due to io.
    const char *buffer_stmt = "ATTACH DATABASE ':memory:' AS buf";
    if (sqlite3_exec(db, buffer_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
        pthread_mutex_unlock(&dbMutex);
        @throw [NSException exceptionWithName:@"DB error attaching memory buffer" reason:@"Couldn't create buffer" userInfo:nil];
    }
    
    //create the table
    const char *sql_stmt = "CREATE TABLE IF NOT EXISTS data (ID INTEGER PRIMARY KEY, timestamp real, sensor_name TEXT, sensor_description TEXT, device_type TEXT, device TEXT, data_type TEXT, value TEXT)";

    if (sqlite3_exec(db, sql_stmt, NULL, NULL, &errMsg) != SQLITE_OK) {
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
    } else {
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
}

#pragma mark - store

- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp {
    //insert into db
    const char *sql_stmt = [[NSString stringWithFormat:@"INSERT INTO buf.data (id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value) VALUES (%lli, %f, %@, %@, %@, %@, %@, %@);", ++lastDataPointid , timestamp, quotedAndEncodedString(sensor), quotedAndEncodedString(description), quotedAndEncodedString(deviceType),
                             quotedAndEncodedString(device), quotedAndEncodedString(dataType), quotedAndEncodedString(value)] UTF8String];

    int ret;
    pthread_mutex_lock(&dbMutex);
    ret = sqlite3_exec(db, sql_stmt, NULL, NULL, NULL);

    if (ret != SQLITE_OK) {
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

#pragma mark - delete

- (void) removeDataBeforeId:(long long) rowId {
    [self removeDataTillId:rowId table:@"buf.data"];
    [self removeDataTillId:rowId table:@"data"];
    
}

/*
 * Removes all data from before a certain date from buffer and main data store
 * @param: dateThreshold The date which marks the threshold, all data older than (from before) the date will be removed
 */
- (void) removeDataBeforeTime:(NSDate *) dateThreshold {
    [self removeDataBeforeTime:dateThreshold fromTable:@"buf.data"];
    [self removeDataBeforeTime:dateThreshold fromTable:@"data"];
}


/*
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

/*
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

- (void) writeDbToFile {
    NSLog(@"Writing data buffer to file");
    
   const char* query = [[NSString stringWithFormat:@"insert into data (id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value) select id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value from buf.data as bv where id > %lli", lastRowIdInStorage] UTF8String];
    pthread_mutex_lock(&dbMutex);
    char* errMsg;
    BOOL succeed = YES;
    if (sqlite3_exec(db, query, NULL, NULL, &errMsg) != SQLITE_OK) {
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
    
    pthread_mutex_unlock(&dbMutex);
    
    //trim the buffer
    [self trimBufferToSize:BUFFER_NR_ROWS];
    
    //Check if database is not too large and remove data if too large
    [self trimLocalStorageIfNeeded];
    
}

/*
 * Checks if database is smaller than MAX_DB_SIZE_ON_DISK and if not, reduces DB size to something that is MAX_DB_SIZE_ON_DISK or 90% of free space plus what we already use by removing oldest rows (with the lowest IDs) from the database
 *
 */
- (void) trimLocalStorageIfNeeded {
    NSNumber *dbSize = [self getDbSize];
    NSNumber *freeSpace = [self getFreeSpaceOnDisk];
    
    //NSLog(@"Size of current local storage: %i kb", ([dbSize intValue]/1000));
    
    
    //Set spacelimit to the min the MAXDB_SIZE_ON_DISK or 90% of the free space + what we already use; this way we never run out of space
    int spaceLimit = MAX_DB_SIZE_ON_DISK < (0.9*[freeSpace intValue]+[dbSize intValue]) ? MAX_DB_SIZE_ON_DISK : (0.9*[freeSpace intValue]+[dbSize intValue]);
    
    NSLog(@"Spacelimit: %i kb", spaceLimit/1000);
    
    if([dbSize intValue] > spaceLimit) {
        
        //calculate percentage of database to be keep
        double percentToKeep = ((spaceLimit / [dbSize doubleValue]));
        
        //calculate number of rows to keep
        long nRowsToKeep = percentToKeep * [self getNumberOfRowsInDb:@"data"];
        
        NSLog(@"Trimming local storage to keep only %d percent (or %i datapoints)", percentToKeep, nRowsToKeep);
        
        //remove oldest rows while keeping nRowsToKeep
        [self trimLocalStorageToRowsToKeep:nRowsToKeep];
    }
}

/*
 * Get the total number of rows in a database
 * @param dbName SQL Identifier of the database name
 */

- (long) getNumberOfRowsInDb:(NSString *) dbName {
    
    const char* queryRowId = [[NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", dbName] UTF8String];
    sqlite3_stmt* stmt;
    
    if (sqlite3_prepare_v2(db, queryRowId, -1, &stmt, NULL) == SQLITE_OK) {
    
        NSInteger ret = sqlite3_step(stmt);
        if (ret == SQLITE_ROW) {
            return sqlite3_column_int(stmt, 0);
        } else {
            NSLog(@"Database error: getting count of rows didn't return SQLITE_ROW");
            return 0;
        }
    } else {
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
    NSLog(@"Local database store size: %@ bytes", [fileAttributes objectForKey:NSFileSize]);
    
    return [fileAttributes objectForKey:NSFileSize];
}

/*
 * Returns the number of bytes of free space on the disk
 */

- (NSNumber *) getFreeSpaceOnDisk {
    NSError *error = nil;
    NSDictionary *fileSystemAttributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:dbPath error:&error];
    NSLog(@"Free space on file system: %@ bytes", [fileSystemAttributes objectForKey:NSFileSystemFreeSize]);
    
    return [fileSystemAttributes objectForKey:NSFileSystemFreeSize];
}


- (void) cleanBuffer {
    //delete from the buffer all persisted rows
    [self removeDataTillId:lastRowIdInStorage table:@"buf.data"];


//      OLD CODE -- has been replaced by removeDataTillId so can probably be removed ^JJ
//    const char* query = [[NSString stringWithFormat:@"DELETE FROM buf.data where id <= %lli", lastRowIdInStorage] UTF8String];
//    pthread_mutex_lock(&dbMutex);
//    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK)
//        NSLog(@"Database Error. cleanBuffer failure: %s", sqlite3_errmsg(db));
//    pthread_mutex_unlock(&dbMutex);
}

- (void) trimBufferToSize:(size_t) nr {
    //delete from the buffer all persisted rows, but keep 'nr' points.
    //Note that the actual size of the buffer might end up to be different from 'nr'. it's a cache, so we're a bit lenient with that.
    //e.g. when there are unpersisted rows, this function will NEVER delete those
    long long nrInMem = lastDataPointid - lastRowIdInStorage;
    long long deleteThreshold = lastRowIdInStorage - MAX(nr - nrInMem, 0);
    [self removeDataTillId:deleteThreshold table:@"buf.data"];

//      OLD CODE -- has been replaced by removeDataTillId so can probably be removed ^JJ
//    const char* query = [[NSString stringWithFormat:@"DELETE FROM buf.data where id <= %lli", deleteThreshold] UTF8String];
//    pthread_mutex_lock(&dbMutex);
//    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK)
//        NSLog(@"Database Error. cleanBuffer failure: %s", sqlite3_errmsg(db));
//    pthread_mutex_unlock(&dbMutex);
}

/*
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

@end
