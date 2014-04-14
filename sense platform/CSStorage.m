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
static const double DB_WRITEBACK_TIMEINTERVAL = 15 * 60;// interval between writing back to storage. Saves power and flash

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
    }
    
    return self;
}

- (void) databaseInit {
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
    
    pthread_mutex_unlock(&dbMutex);
}

#pragma mark - store

- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp {
    //insert into db
    const char *sql_stmt = [[NSString stringWithFormat:@"INSERT INTO buf.data (id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value) VALUES (%lli, %f, '%@', '%@', '%@', '%@', '%@', '%@');", ++lastDataPointid , timestamp, sensor, description, deviceType, device, dataType, value] UTF8String];

    int ret;
    pthread_mutex_lock(&dbMutex);
    ret = sqlite3_exec(db, sql_stmt, NULL, NULL, NULL);

    if (ret != SQLITE_OK) {
        NSLog(@"Database Error inserting sensor data into buffer: %s", sqlite3_errmsg(db));
        //@throw [NSException exceptionWithName:@"DB error" reason:[NSString stringWithCString:errMsg encoding:NSUTF8StringEncoding] userInfo:nil];
    }
    pthread_mutex_unlock(&dbMutex);
}

#pragma mark - retrieve

- (NSArray*) getSensorDataPointsFromId:(long long) start limit:(size_t) limit {
    NSMutableArray* results = [NSMutableArray new];
    const char* query = [[NSString stringWithFormat:@"SELECT id, timestamp, sensor_name, sensor_description, device_type, device, data_type, value FROM data where id >= %lli limit %zu", start, limit] UTF8String];
    sqlite3_stmt* stmt;
    pthread_mutex_lock(&dbMutex);
    NSInteger ret = sqlite3_prepare_v2(db, query, -1, &stmt, NULL);
    if (ret == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            CSDataPoint* p = [[CSDataPoint alloc] init];
            p.dataPointID = sqlite3_column_int64(stmt, 0);
            p.timestamp = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_double(stmt, 1)];
            p.sensor = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 2)];
            p.sensorDescription = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 3)];
            p.deviceType = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 4)];
            p.deviceUUID = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 5)];
            p.dataType = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 6)];
            p.timeValue = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, 7)];

            [results addObject:p];
        }
    } else if (ret != SQLITE_NOTFOUND) {
        NSLog(@"database error. getSensorDataPointsFromId: %li.", (long)ret);
    }
    sqlite3_finalize(stmt);
    pthread_mutex_unlock(&dbMutex);

    return results;
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
}

- (void) cleanBuffer {
    //delete from the buffer all persisted rows
    const char* query = [[NSString stringWithFormat:@"DELETE FROM buf.data where id <= %lli", lastRowIdInStorage] UTF8String];
    pthread_mutex_lock(&dbMutex);
    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK)
        NSLog(@"Database Error. cleanBuffer failure: %s", sqlite3_errmsg(db));
    pthread_mutex_unlock(&dbMutex);
}


- (void) cleanPersistentDb {
    //TODO: do something usefull, like deleting uploaded points, look at disk space... whatever.
    NSLog(@"Deleting old values from db file");
    //delete values older than 60 days
    const char* query = [[NSString stringWithFormat:@"DELETE FROM data where timestamp < %f", ([[NSDate date] timeIntervalSince1970] - 60.0 * 24 * 60 * 60)] UTF8String];
    pthread_mutex_lock(&dbMutex);
    if (sqlite3_exec(db, query, NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"cleanPersistentDb failure: %s", sqlite3_errmsg(db));
    }
    pthread_mutex_unlock(&dbMutex);
}

@end
