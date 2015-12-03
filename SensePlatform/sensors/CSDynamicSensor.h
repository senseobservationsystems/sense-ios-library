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

#import "CSSensor.h"


/** Sensor that be used to create a new sensor during runtime and store data in it. */
@interface CSDynamicSensor : CSSensor {
    NSString* sensorName;
    NSString* displayName;
    NSString* deviceType;
    NSString* dataType;
}

/** Init new sensor for this device.
 @param name Name of the sensor
 @param dispName Description of the sensor used to display name
 @param devType Device type that the sensor belongs to
 @param datType Data type of the values being stored in the sensor
 @param fields Dictionary that stores all the fields with values as a JSON object
 */
- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields;

/** Init new sensor for any device.
 @param name Name of the sensor
 @param dispName Description of the sensor used to display name
 @param devType Device type that the sensor belongs to
 @param datType Data type of the values being stored in the sensor
 @param fields Dictionary that stores all the fields with values as a JSON object
 @param device Dictionary that describes the device.
 */
- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields device:(NSDictionary*) device;

/**
 Store a value in the sensor.
 @param value The value to be stored, will be stored as a JSON string object. Can be anything.
 @param timestamp Seconds since 1970 timestamp that describes time the value was collected.
 */
- (void) commitValue:(id)value withTimestamp:(NSDate*)time;
@end

