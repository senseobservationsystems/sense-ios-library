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

//Include all sensors
#include "CSSensor.h"
#include "CSSensorIds.h"

extern NSString * const kCSDATA_TYPE_JSON;
extern NSString * const kCSDATA_TYPE_INTEGER;
extern NSString * const kCSDATA_TYPE_FLOAT;
extern NSString * const kCSDATA_TYPE_STRING;
extern NSString * const kCSDATA_TYPE_BOOL;

extern NSString* const kCSNewSensorDataNotification;
extern NSString* const kCSNewMotionDataNotification;

typedef enum {BPM_SUCCES=0, BPM_CONNECTOR_NOT_PRESENT, BPM_NOT_FOUND, BPM_UNAUTHORIZED, BPM_OTHER_ERROR} BpmResult;
typedef void(^bpmCallBack)(BpmResult result, NSInteger newOkMeasurements, NSInteger newFailedMeasurements, NSDate* latestMeasurement);

/**
 * This is the high-level interface for the sense platform.
 */
@interface CSSensePlatform : NSObject
/// Initializes the sense platform.
+ (void) initialize;
/// Returns a list of available sensors of the device
+ (NSArray*) availableSensors;
/// To be called upon termination of the app, allows the platform to flush it's caches to Common Sense
+ (void) willTerminate;
/// Flush data to Common Sense
+ (void) flushData;
/// Flush data to Common Sense, return after the flush is completed
+ (void) flushDataAndBlock;
/// Set the credentials to log in on Common Sense
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password;
+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash;

/** Logout
 * Flush data to Common Sense and logout
 */
+ (void) logout;

/** Register a user in Common Sense
 * @param user the username
 * @param password the plain text password
 * @param email the user's email address
 * @returns Wether the registration succeeded
 */
+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password withEmail:(NSString*) email;

/** Get the session cookie for Common Sense
 *  Once the user has logged in to CommonSense this method can be used to retrieve the session cookie for an apps own usage. Note that the format is "session_id=<session_id>".
 *  @returns The session id to communicate with CommonSense, nil if there is no session cookie.
 */
+ (NSString*) getSessionCookie;

/// Setup the platform for use with iVitality
+ (void) applyIVitalitySettings;

/** Add a data point for a sensor that belongs to this device, if the sensor doesn't exist it will be created
 * @param sensorName the sensor name
 * @param displayName the display name of the sensor
 * @param description the deviceType/description of the sensor
 * @param dataType the data type for the data of the sensor.
 * @param stringValue A JSON encoded data point
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description dataType:(NSString*)dataType stringValue:(NSString*)value timestamp:(NSDate*)timestamp;

/** Add a data point for a sensor that belongs to this device, if the sensor doesn't exist it will be created. 
 * @param sensorName the sensor name
 * @param displayName the display name of the sensor
 * @param description the deviceType/description of the sensor
 * @param dataType the data type for the data of the sensor.
 * @param jsonValue The data object. Can be any JSONSerializable object (e.g. NSDictionary,NSArray, NSNumber, NSString).
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description dataType:(NSString*)dataType jsonValue:(id)value timestamp:(NSDate*)timestamp;

/** Add a data point for a sensor, if the sensor doesn't exist it will be created
 * @param sensorName the sensor name
 * @param displayName the display name of the sensor
 * @param description the deviceType/description of the sensor
 * @param dataType the data type for the data of the sensor.
 * @param stringValue A JSON encoded data point
 * @param deviceType the type of the device the sensor should be attached to (nil for no device)
 * @param deviceUUID the uuid of the device the sensor should be attached to (nil for no device)
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID dataType:(NSString*)dataType stringValue:(NSString*)value timestamp:(NSDate*)timestamp;


/** Add a data point for a sensor, if the sensor doesn't exist it will be created
 * @param sensorName the sensor name
 * @param displayName the display name of the sensor
 * @param description the deviceType/description of the sensor
 * @param dataType the data type for the data of the sensor.
 * @param jsonValue The data object. Can be any JSONSerializable object (e.g. NSDictionary,NSArray, NSNumber, NSString).
 * @param deviceType the type of the device the sensor should be attached to (nil for no device)
 * @param deviceUUID the uuid of the device the sensor should be attached to (nil for no device)
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID dataType:(NSString*)dataType jsonValue:(id)value timestamp:(NSDate*)timestamp;


/// This function isn't operational.
+ (void) synchronizeWithBloodPressureMonitor:(bpmCallBack) callback;
/** Retrieve a number of values of a sensor from Common Sense. returns nrLastPoints of the latest values.
 * @param name The name of the sensor to get data from
 * @param onlyFromDevice Wether or not to only look through sensors that are part of this device. Searches all sensors, including those of this device, if set to NO
 * @param nrLastPoints Number of points to retrieve, this function always returns the latest values for the sensor.
 * @returns an array of values, each value is a dictionary that describes the data point
 */
+ (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;
/** Give feedback on a state sensor.
 * @param state The state to give feedback on.
 * @param from The start date for the feedback.
 * @param to The end date for the feedback.
 * @param label The label of the Feedback, e.g. 'Sit'
 */
+ (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;
@end
