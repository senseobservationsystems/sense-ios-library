//
//  DSECommonSenseProxy.h
//  SensePlatform
//
//  Created by Joris Janssen on 16/08/15.
//
//

#import <Foundation/Foundation.h>

/**
 *	The DSECommonSenseProxy class consists of static methods that wrap the API so that it is more convenient to call. 
 
	It is up to the user to either call the API in a synchronous or asynchronous manner. Every API call will have two callback methods that get called whenever the call returns. The success method will be called when the API call was successfull. The failure call will be called when the API call was not successfull.
 
		- In cases where the API call was successfull, resulting data will be passed on to the success callback functions as parameters. Please see indivdual functions for details.
 
		- The failure callback will be called with an NSError object as a parameter. The object can be used to get details about the error by parsing the response object. Specifically, the NSError response code will correspond to the code that was received from the server. The NSError response message will correspond to the message that was received from the server.
 
	
	The DSECommonSenseProxy class does not now about DataStorageEngine concepts, it simply wraps the API that is available for CommonSense. Any translations between concepts in the DataStorageEngine and CommonSense should be made by other objects (most notably the difference between Source and Device). 
 
	The DSECommonSenseProxy uses a Session ID and Application Key to get authorized for API access. These parameters are managed automatically but can be set by others as well. -->> do we want this?
 
 */
@interface DSECommonSenseProxy : NSObject

@property NSString* sessionID;		//Do we want the proxy to manage the session ID? If we don't it has to be provided to every method.
@property NSString* applicationKey; //Do we want the proxy to manage the app key? If we don't it has to be provided to every method.

#pragma mark User functions
/**
 @name Users
 */

/**
 Registers a new user as an account to CommonSense

 @note Note that when the user is registered, the user is not yet logged in. This should be done after the registeration succeeds by the user/developer.
 
 @param username		A user account in commonsense is uniquely identified by a username. It can be any string, however it cannot exist yet in the commonsense account database. The call will fail if the user account already exists.
 @param password		A password in commonsense does not have any specific requirements. It will be MD5 hashed before sending to the server so the user does not have to provide a hashed password.
 @param email			Optional, an email address to link to the account
 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) registerUser: (NSString *) username andPassword: (NSString *) password andEmail: (NSString *) email andSuccessCallback:(void(^)()) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;

/**
 Login a user
 
 @note If a user is already logged in this call will fail. That user should be logged out first before a new login attempt can be made. The failureCallback will be called in that case.
 
 @param username		A user account in commonsense is uniquely identified by a username.
 @param password		A password in commonsense does not have any specific requirements. It will be MD5 hashed before sending to the server so the user does not have to provide a hashed password.
 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) loginUser: (NSString *) username andPassword: (NSString *) password andSuccessCallback:(void(^)()) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;

/**
 Logout the currently logged in user.
 
 @note If no user is logged in this call will fail. The failureCallback will be called in that case.

 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) logoutCurrentUserWithSuccessCallback:(void(^)()) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;

/**
 Delete the currently logged in user.
 
 @warning This will permanently all data, sensors, and devices for this user.
 
 @note If no user is logged in this call will fail. The failureCallback will be called in that case.
 
 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) deleteCurrentUserWithSuccessCallback:(void(^)()) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


#pragma mark Device (DSESource backend equivalent) functions
/**
 @name Sensors and Devices (DSESource backend equivalent)
*/

/** 
 Get all devices for the currently logged in user.
 
 This will fetch all the devices for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one device.
 
 @param successCallback A callback method that will be called in the case the API call succeeds. It receives the resulting array of devices.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) getDevicesWithSuccessCallback:(void(^)(NSArray* devices)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


/**
 Get all sensors for the currently logged in user.
 
 This will fetch all the sensors for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one sensor.
 
 @param successCallback A callback method that will be called in the case the API call succeeds. It receives the resulting array of sensors.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) getSensorsWithSuccessCallback:(void(^)(NSArray* sensors)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


/** 
 Create a new sensor in the commonsense backend
 
 Each sensor in commonsense is uniquely identified by a name and devicetype combination. If this combination already exists in the commonsense backend this call will fail.
 
 @param name			Name of the sensor to create. This will be used to identify the sensor.
 @param displayName		Extra field to make sensor name more readable if necessary when displaying it.
 @param deviceType		Name of the device type the sensor belongs to.
 @param dataType		Type of data that the sensor stores.
 @param dataStructure	Structure of the data in the data; can be used to specify the JSON structure in the sensor.
 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSuccessCallback:(void(^)(NSArray* sensors)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


//Add sensor to a device; creates a device if it doesnt exist yet; Do we need these?
+ (void) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSuccessCallback:(void(^)(NSDictionary* device)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;
+ (void) addSensorWithID: (NSString *) csSensorID toDeviceWithName: (NSString *) csDeviceName andUUID: (NSString *) UUID andSuccessCallback:(void(^)(NSDictionary* device)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


//Get sensors for a device
//	I don't think this will be necessary; the less API calls we use the better it will perform

//Get device for a sensor
//	I don't think this will be necessary


#pragma mark Data functions
/**
 @name Data
 */


/** 
 Upload sensor data to commonsense
 
 Data can be coming from multiple sensors.
 
 @param data			NSArray of datapoints. Each datapoint should be an NSDictionary with fields called "sensorID" (NSString), "value" (id), and "date" (NSDate *). These fields will be parsed into the correct form for uploading to commonsense.
 @param successCallback A callback method that will be called in the case the API call succeeds. It does not receive any input parameters.
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) postData: (NSArray *) data withSuccessCallback:(void(^)()) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;

/**
 Download sensor data from commonsense from a certain date till now.
 
 @note The downloaded data will be passed as an NSArray * to the success callback method from which it can be further processed.
 
 @param csSensorID		Identifier of the sensor from CommonSense for which to download the data.
 @param fromDateDate	Date from which to download data. Datapoints after this date will be included in the download. Datapoints from before this date will be ignored.
 @param successCallback A callback method that will be called in the case the API call succeeds. It receives an NSArray * parameter with the resulting data. Each object in the array will be an NSDictionary with fields "value", "sensorID", and "date".
 @param failureCallback A callback method that will be called in case of failing the API call. It will receive an NSError object with details about the cause of the failure.
 */
+ (void) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSuccessCallback:(void(^)(NSArray* data)) successCallback andFailureCallback:(void(^)(NSError* error)) failureCallback;


//Upload datapoints for a specific sensor
//	I don't we will need this

@end;
