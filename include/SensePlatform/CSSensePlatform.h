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

//Include all header files
#include "CSVersion.h"
#include "CSSensor.h"
#include "CSSensorIds.h"
#include "CSSensorRequirements.h"
#include "CSSettings.h"
#include "CSLocationPermissionProtocol.h"

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
This is the high-level interface for the iOS sense platform library. CSSensePlatform uses only class methods so there is never an instance of the CSSensePlatform. Instead, whenever
	
	[CSSensePlatform initialize];
 
is called, this initializes a CSSensorStore object (a singleton) which coordinates most of the behavior in the app including local and remote persistency. Next to that, the CSSensePlatform provides functions for logging in, logging out, and registering a user, storing data in sensors, and retrieving data from sensors.

 */
@interface CSSensePlatform : NSObject

/** @name Initialization */

/// Initializes the sense platform. This creates an instance of the CSSensorStore object.
+ (void) initialize;

/**
 * Initialize the Sense Platform
 * @param applicationKey the application key to identify this application to Common Sense
 */
+ (void) initializeWithApplicationKey: (NSString*) applicationKey;



/** @name User management */

/** 
Register a user in CommonSense backend.
 
There are no specific requirements for the user (username) or password. Username cannot exist yet as a CommonSense user though. The email address does not have to be unique. The returning boolean indicates if registration was successfull. If it was, the user is automatically logged in (the developer does not have to do this anymore) and the credentials are stored in the settings.
 
Note that if registration fails, there is no way for the developer or end-user to know why it failed. This could be because of a username that is already in use, because of a problem on the cloud side, or because of a missing internet connection (among others).
 
@param user the username
@param password the plain text password
@param email the user's email address
@return Wether the registration succeeded
*/
+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password withEmail:(NSString*) email;

/**
 *  Set the credentials to log in on Common Sense
 *
 * This sets the credentials in the settings and logs in at commonsense cloud. If the login is successfull the kCSGeneralSettingUploadToCommonSense is enabled.
 *
 * Note that if login fails, there is no way for the developer or end-user to know why it failed. This could be because of a wrong username / password combination, because of a problem on the cloud side, or because of a missing internet connection (among others).
 *
 *  @param user     Username used to identify the user (this does not necessarily have to be an email address)
 *  @param password The password connected to the user account (not hashed yet)
 *  @deprecated use loginWithUser:andPassword:andError instead
 *
 */
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password;

/**
 *  Set the credentials to log in on Common Sense
 *
 *  This sets the credentials in the settings and logs in at commonsense cloud. If the login is successfull the kCSGeneralSettingUploadToCommonSense is enabled.
 *
 *  Returns a descriptive error if the login process fails.
 *
 *  @param user     Username used to identify the user (this does not necessarily have to be an email address)
 *  @param password The password connected to the user account (not hashed yet)
 *  @param error    error
 *
 *  @return whether the login succeeded
 */
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password andError:(NSError **) error;

/**
 *  Set the credentials to log in on Common Sense
 *
 *  This sets the credentials in the settings and logs in at commonsense cloud. If the login is successfull the kCSGeneralSettingUploadToCommonSense is enabled.
 *
 *  Note that if login fails, there is no way for the developer or end-user to know why it failed. This could be because of a wrong username / password combination, because of a problem on the cloud side, or because of a missing internet connection (among others).
 *
 *  @param user         username
 *  @param passwordHash md5 hased password
 *  @deprecated use loginWIthUser:andPasswordHash:andError instead
 *
 *  @return whether the login is succsesful or not
 */

+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash;

/**
 *  Set the credentials to log in on Common Sense
 *
 *  This sets the credentials in the settings and logs in at commonsense cloud. If the login is successfull the kCSGeneralSettingUploadToCommonSense is enabled.
 *
 *  Returns a descriptive error if the login process fails.
 *
 *  @param user         username
 *  @param passwordHash md5 hased password
 *  @param error        error
 *
 *  @return whether the login is succsesful or not
 */
+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash andError:(NSError **) error;

/** Logout
This removes credentials from the settings and stops the uploading to CommonSense.
*/
+ (void) logout;

/**
 *  return if user is loggedin
 *
 *  @return state whether user is logged in
 */
+ (BOOL) isLoggedIn;

/** Get the session cookie for Common Sense

Whenever a user is logged in, it uses a session id from CommonSense to be able to interact with the cloud. To be able to manually call the CommonSense API one would need to obtain that Session ID. This is returned by the getSessionCookie function. Note that the format is "session_id=<session_id>".

@returns The session id to communicate with CommonSense, nil if there is no session cookie.
 */
+ (NSString*) getSessionCookie;


/** @name Sensordata storage and access */

/** Add a data point for a sensor that belongs to this device, using a JSON encoded string.
 
  If the sensor doesn't exist it will be created. Data will first be stored locally, and is directly available from local storage. After an upload has occured it is also available remotely.
 
 @param sensorName the sensor name
 @param displayName the display name of the sensor
 @param description the deviceType/description of the sensor
 @param dataType the data type for the data of the sensor.
 @param value A JSON encoded data point
 @param timestamp An NSDate object describing the time and date the value object occured. It will be used to organize the storing of the data and to later fetch the data.
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description dataType:(NSString*)dataType stringValue:(NSString*)value timestamp:(NSDate*)timestamp;

/** Add a data point for a sensor that belongs to this device, using a JSONSerializable value object.
 
 If the sensor doesn't exist it will be created. Data will first be stored locally, and is directly available from local storage. After an upload has occured it is also available remotely.
 
 @param sensorName the sensor name
 @param displayName the display name of the sensor
 @param description the deviceType/description of the sensor
 @param dataType the data type for the data of the sensor.
 @param value The data object. Can be any JSONSerializable object (e.g. NSDictionary,NSArray, NSNumber, NSString).
 @param timestamp An NSDate object describing the time and date the value object occured. It will be used to organize the storing of the data and to later fetch the data.
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description dataType:(NSString*)dataType jsonValue:(id)value timestamp:(NSDate*)timestamp;

/** Add a data point for a sensor using a JSON encoded string object for the value, for a specific device.
 
 If the sensor doesn't exist it will be created. Data will first be stored locally, and is directly available from local storage. After an upload has occured it is also available remotely.
 
 @param sensorName the sensor name
 @param displayName the display name of the sensor
 @param description the deviceType/description of the sensor
 @param dataType the data type for the data of the sensor.
 @param value A JSON encoded data point
 @param deviceType the type of the device the sensor should be attached to (nil for no device)
 @param deviceUUID the uuid of the device the sensor should be attached to (nil for no device)
 @param timestamp An NSDate object describing the time and date the value object occured. It will be used to organize the storing of the data and to later fetch the data.
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID dataType:(NSString*)dataType stringValue:(id)value timestamp:(NSDate*)timestamp;


/** Add a data point for a sensor using a JSONSeriazable data object for the value, for a specific device.
 
 If the sensor doesn't exist it will be created. Data will first be stored locally, and is directly available from local storage. After an upload has occured it is also available remotely.
 
 @param sensorName the sensor name
 @param displayName the display name of the sensor
 @param description the deviceType/description of the sensor
 @param dataType the data type for the data of the sensor.
 @param value The data object. Can be any JSONSerializable object (e.g. NSDictionary,NSArray, NSNumber, NSString).
 @param deviceType the type of the device the sensor should be attached to (nil for no device)
 @param deviceUUID the uuid of the device the sensor should be attached to (nil for no device)
 @param timestamp An NSDate object describing the time and date the value object occured. It will be used to organize the storing of the data and to later fetch the data.
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID dataType:(NSString*)dataType jsonValue:(id)value timestamp:(NSDate*)timestamp;


/** Retrieve a number of values of a sensor from Common Sense.
 
This only looks at remote data, not at locally stored data. You can be sure that the data that is returned is for the specific user account. Can only be used if the user is logged in.-

@param name The name of the sensor to get data from
@param onlyFromDevice Wether or not to only look through sensors that are part of this device. Searches all sensors, including those of this device, if set to NO
@param nrLastPoints Number of points to retrieve, this function always returns the latest values for the sensor.
@return an array of values, each value is a dictionary that describes the data point
 */
+ (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;

/** Retrieve all the sensor data stored locally between a certain time interval.
 
Sensor data is stored in an SQLite table and can be retrieved by sensor and date. There are a few limitations on the storage:
 
- It is kept for 30 days. Data older than 30 days is removed.
- A maximum of 100 mb is kept. Users are likely to remove the app if there would be more storage space used. This should normally be ample for 30 days of data.
- The total amount of storage is limited if the disk space of the device is smaller than what is needed by the.

These limitations are treated in a first in first out way. Hence, older data is removed first.

@warning Sensordata is not stored in a user specific format. Hence, when the user logs out or the app starts to being used by a different user on the same device, the old settings and data remains accessible to the new user.
 
@param name The name of the sensor to get the data from
@param startDate The date and time at which to start looking for datapoints
@param endDate The date and time at which to stop looking for datapoints
@return an array of values, each value is a dictonary that descirbes the data point
*/
+ (NSArray*) getLocalDataForSensor:(NSString*) name from:(NSDate*) startDate to: (NSDate*) endDate;


/** @name Permissions */

/**
 
 Ask the CSSensePlatform to request location permissions from the user. This will ask the user for kCLAuthorizationStatusAuthorizedAlways permissions, meaning the app can always obtain location updates.
 The function will present the location permission dialog to the user, asynchronously. After the user responds to this dialog by either granting or denying the permissions, the corresponding callback on the provided delegate will be called. Make sure the delegate implements the protocol!
 The reason we need a delegate object that implements predefined callback functions is that the permission request dialog is presented asynchronously to the user. That means that we would lose any callback context provided to this function. Using an object implementing a protocol, we can temporarily store a reference to the object and callback later when the user granted or denied the permissions.
 IMPORTANT: This function will do nothing on iOS < 8.
 IMPORTANT: If the user denies permission, the app will not run in the background until the user explicitly grants permission to the app in the iOS settings screen.
 
 @param delegate Object implementing the CSLocationPermissionProtocol protocol. A weak reference to this object will be stored, so don't destroy it before the callback is called. Typically this will be a ViewController object.
 */
+ (void) requestLocationPermissionWithDelegate: (id <CSLocationPermissionProtocol>) delegate;

/**
 
 Request the current location permission status for the app. 
 This function will return one of three possible values:
    - kCLAuthorizationStatusNotDetermined: there is no permission status yet. In this case the permission should be asked from the user using requestLocationPermissionWithDelegate, or it will be done automatically once sensing is started.
    - kCLAuthorizationStatusDenied: the user has denied location permissions. In this case the app will not be able to run in the background, and the only way to remedy this is for the user to explicitly grant permission in the iOS -> settings screen.
    - kCLAuthorizationStatusAuthorizedAlways: the app has obtained the required permissions, no action needed.
 */
+ (CLAuthorizationStatus) locationPermissionState;

/** @name Miscellaneous */

/**
 Returns a unique identifier for the device.
 
 Note that Apple has made some changes to the way devices can be identified. From a privacy perspective they have decided to not create device specific identifiers anymore, but instead deliver app specific identifiers. This means that when a certain user removes the app and reinstalls, it might give a different identifier than before. The identifier will still be unique, but subsequent installs cannot be linked anymore using the device ID.
 
 @return Unique identifier for the device
 */
+ (NSString*) getDeviceId;


/** Give feedback on a state sensor so that it can be used to learn.
 
 Note that this functionality is not being used right now.
 
 @param state The state to give feedback on.
 @param from The start date for the feedback.
 @param to The end date for the feedback.
 @param label The label of the Feedback, e.g. 'Sit'
 */
+ (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;

/// Returns a list of available sensors of the device
+ (NSArray*) availableSensors;

/// return true if sensor with specific id is available. list of id available on CSSensorIds.h
+ (BOOL) isAvailableSensor:(NSString*) sensorID;

/// To be called upon termination of the app, allows the platform to flush it's caches to Common Sense
+ (void) willTerminate;
/// Flush data to Common Sense
+ (void) flushData;
/// Flush data to Common Sense, return after the flush is completed
+ (void) flushDataAndBlock;

/** This function isn't operational.
@deprecated This function is not operational anymore. If it is working for you that is dumb luck; don't count on it.
@param callback I don't know what this is .. ^JJ
 */
+ (void) synchronizeWithBloodPressureMonitor:(bpmCallBack) callback;

/** Setup the platform for use with iVitality
@deprecated This function will be removed in future version
 */
+ (void) applyIVitalitySettings;


@end
