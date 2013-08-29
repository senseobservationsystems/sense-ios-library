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
#import "CSSensorIds.h"

/** The base object for each sensor.
 */
@interface CSSensor : NSObject {
	BOOL isEnabled;
	//delegate
	id dataStore;
}

@property (assign) BOOL isEnabled;
///The data store the sensor commits its obtained values to
@property id dataStore;
@property (readonly) NSString* sensorId;

///Method to check wether the sensor matches the given description of the sensor
- (BOOL) matchesDescription:(NSDictionary*) description;

///Method that will be invoked when the sensor is enabled/disabled
- (void) enabledChanged: (id) notification;

//overridden by subclass
///Returns name of the sensor
- (NSString*) name;
///Returns the display name of the sensor
- (NSString*) displayName;
///Returns the device type of the sensor
- (NSString*) deviceType;
///Returns the description of the sensor
- (NSDictionary*) sensorDescription;
//The device of the sensor
- (NSDictionary*) device;
///Returns wether this sensor is available
+ (BOOL) isAvailable;
///Returns the sensor id of the sensor, a unique name that is used by the library to uniquely identify the sensor. This is NOT the id of the sensor in Common Sense
- (NSString*) sensorId;

///Create sensor id
+ (NSString*) sensorIdFromName:(NSString*)name andDeviceType:(NSString*)deviceType andDevice:(NSDictionary*)device;
///Extract sensor name from the sensor id
+ (NSString*) sensorNameFromSensorId:(NSString*) sensorId;
@end
