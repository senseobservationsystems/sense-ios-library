//
//  CSStorage.h
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import <Foundation/Foundation.h>

/**
 Handles sensor data storage in an SQLite database
 
 Data is first stored in a buffer in memory. After each 1000 datapoints it is written to disk. Disk storage is limited to 100mb. If this limit is exceeded or the disk is full, 20% of the oldest datapoints are removed.
 */
@interface CSStorage : NSObject

- (id) initWithPath:(NSString*) databaseFilePath;

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
- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp;

- (NSArray*) getSensorDataPointsFromId:(long long) start limit:(size_t) limit;

/** Retrieve all the sensor data stored in the database between a certain time interval.
 * @param name The name of the sensor to get the data from
 * @param startDate The date and time at which to start looking for datapoints
 * @param endDate The date and time at which to stop looking for datapoints
 * @return an array of values, each value is a dictonary that descirbes the data point
 */
- (NSArray*) getDataFromSensor: (NSString*) name from: (NSDate*) startDate to: (NSDate*) endDate;


- (void) removeDataBeforeId:(long long) rowId;

/**
 * Removes all data from before a certain date from buffer and main data store
 * @param dateThreshold NSDate which marks the threshold, all data older than (from before) the date will be removed
 */
- (void) removeDataBeforeTime:(NSDate *) dateThreshold;


- (long long) getLastDataPointId;
- (void) flush;

- (void) storeSensorDescription:(NSString*) jsonDescription forSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device;

- (NSString*) getSensorDescriptionForSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device;

/**
 * Reduces nr of rows in database by removing a percentage of the oldest rows from the db and freeing up pages for new incoming data
 *  @param: percentToKeep The percentage of rows to keep
 */
- (void) trimLocalStorageTo: (double) percentToKeep;

/*
 * Returns the size of the local storage database in bytes
 */
- (NSNumber *) getDbSize;

/**
 * Delete all rows of the database except the nrToKeep most recent rows based on id field
 * @param nrToKeep Number of most recent rows to keep (oldest rows will be removed first)
 *
 */
- (void) trimLocalStorageToRowsToKeep:(size_t) nrToKeep;

/**
 * Queries the number of rows in the table and returns the result
 * @param table Name of the table to query
 * @return Number of rows in the table
 */
- (long) getNumberOfRowsInTable:(NSString *) table;

@end