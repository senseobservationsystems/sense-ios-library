/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "CSDataStore.h"
#import "CSSender.h"
#import "CSSensor.h"

/**
 Handles sensor data storing and uploading. Start all sensors and data providers.
 
 Data is stored locally for 30 days. After a succesfull upload, older data is removed.
 */
@interface CSSensorStore : NSObject <CSDataStore> {
}

@property (readonly) NSArray* allAvailableSensorClasses;
@property (readonly) NSArray* sensors;
@property (readonly) CSSender* sender;


+ (CSSensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;
- (void) setSyncRate: (int) newRate;
- (void) addSensor:(CSSensor*) sensor;

- (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;

/** 
 * Retrieve data from a sensor that is stored locally between a certain time interval
 * @param name The name of the sensor as an NSString
 * @param startDate The date and time of the first datapoint to look for (inclusive)
 * @param endDate The data and time of the last datapoint to look for (exclusive)
 * @result An array with dictionaries of time-value pairs
 */
- (NSArray*) getLocalDataForSensor:(NSString *)name from:(NSDate *)startDate to:(NSDate *)endDate;

// remove all sensor data that are stored locally
- (void) removeLocalData;

- (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk 
 * - delete
 */
- (void) forceDataFlush;
- (void) forceDataFlushAndBlock;
- (void) generalSettingChanged: (NSNotification*) notification;

// passes on the requestLocationPermission function call to the locationProvider
- (void) requestLocationPermission;
// passes on the locationPermissionState function to the locationProvider
- (CLAuthorizationStatus) locationPermissionState;

@end
