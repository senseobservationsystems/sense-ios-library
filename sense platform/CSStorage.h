//
//  CSStorage.h
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import <Foundation/Foundation.h>

@interface CSStorage : NSObject
- (id) initWithPath:(NSString*) databaseFilePath;
- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp;
- (NSArray*) getSensorDataPointsFromId:(long long) start limit:(size_t) limit;
- (void) removeDataBeforeId:(long long) rowId;

/*
 * Removes all data from before a certain date from buffer and main data store
 * @param: dateThreshold Date which marks the threshold, all data older than (from before) the date will be removed
 */
- (void) removeDataBeforeTime:(NSDate *) dateThreshold;


- (long long) getLastDataPointId;
- (void) flush;

- (void) storeSensorDescription:(NSString*) jsonDescription forSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device;
- (NSString*) getSensorDescriptionForSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device;

/** Retrieve all the sensor data stored in the database between a certain time interval.
 * @param name The name of the sensor to get the data from
 * @param startDate The date and time at which to start looking for datapoints
 * @param endDate The date and time at which to stop looking for datapoints
 * @return an array of values, each value is a dictonary that descirbes the data point
 */
- (NSArray*) getDataFromSensor: (NSString*) name from: (NSDate*) startDate to: (NSDate*) endDate;
@end
