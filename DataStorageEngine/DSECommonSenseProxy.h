//
//  DSECommonSenseProxy.h
//  SensePlatform
//
//  Created by Joris Janssen on 16/08/15.
//
//

#import <Foundation/Foundation.h>


/**
 *	The DSECommonSenseProxy class consists of methods that wrap the API.
 
	Only API calls there are necessary for the DataStorageEngine have been implemented here. All calls are made in a synchronous manner. It is up to the user to either call the API in a synchronous or asynchronous manner.
	
	The DSECommonSenseProxy class does not now about DataStorageEngine concepts, it simply wraps the API that is available for CommonSense. Any translations between concepts in the DataStorageEngine and CommonSense should be made by other objects (most notably the difference between Source and Device). 
 
	The DSECommonSenseProxy an Application Key to get authorized for API access. This parameter is simply stored on initialization but not managed by the DSECommonSenseProxy. If they should change, simply making a new instance of the proxy would be sufficient.
 
	The DSECommonSenseProxy knows about two servers: the CommonSense live server (for production) and the CommonSense staging server (for testing). Which server to use can be selected on initialization.
 
	Error handling is done through NSError objects. Server side error codes will be directly copied into the error. Client side errors have their own codes specified in DSEErrorCodes.h. The userInfo object will contain an error message if applicable, or will be nil otherwise. All DataStorageEngine will use the error domain "nl.sense.DataStorageEngine.ErrorDomain".
 
 */
@interface DSECommonSenseProxy : NSObject {
	NSString *appKey;					//The app key
	NSString *urlBase;					//The base url to use, will differ based on whether to use live or staging server
	NSString *urlAuth;				//The base url to use for authentication, will differ based on whether to use live or staging server
}


/**
 Default initializaler for the DSECommonSenseProxy.
 
 Takes an app key that will be used throughout the proxies lifetime. Needs to know whether to talk to the live server or the staging server. This cannot be changed during the proxies lifetime. If you need to change this you simply init a new commonsense proxy.
 
 @param useLiveServer	If YES, the live server will be used. If NO, the staging server will be used.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @result				Initialized DSECommonSenseProxy
*/
- (id) initAndUseLiveServer: (BOOL) useLiveServer withAppKey: (NSString *) theAppKey;

#pragma mark User
/**
 @name Users
 */

/**
 Login a user
 
 @note If a user is already logged in this call will fail. That user should be logged out first before a new login attempt can be made. The failureCallback will be called in that case.
 
 @param username		A user account in commonsense is uniquely identified by a username. Cannot be empty.
 @param password		A password in commonsense does not have any specific requirements. It will be MD5 hashed before sending to the server so the user does not have to provide a hashed password. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @return				Session ID. Will be nil if the call fails.
 */
- (NSString *) loginUser: (NSString *) username andPassword: (NSString *) password andError: (NSError **) error;

/**
 Logout the currently logged in user.
 
 @param sessionID		The sessionID of the user to logout. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @return				Whether or not the logout finished succesfully.
 */
- (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error;


//- (BOOL) deleteCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error;

#pragma mark Sensors and Devices
/**
 @name Sensors and Devices (DSESource backend equivalent)
*/


/**
 Create a new sensor in the commonsense backend
 
 Each sensor in commonsense is uniquely identified by a name and devicetype combination. If this combination already exists in the commonsense backend this call will fail.
 
 @param name			Name of the sensor to create. This will be used to identify the sensor. Required.
 @param displayName		Extra field to make sensor name more readable if necessary when displaying it. Not required.
 @param deviceType		Name of the device type the sensor belongs to. Required.
 @param dataType		Type of data that the sensor stores. Required.
 @param dataStructure	Structure of the data in the data; can be used to specify the JSON structure in the sensor. Not required.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Dictionary with the information of the created sensor.
 */
- (NSDictionary *) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSessionID: (NSString *) sessionID andError: (NSError **) error;


/**
 Get all sensors for the currently logged in user.
 
 This will fetch all the sensors for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one sensor.
 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Array of sensors. Each object will be an NSDictionary with the resulting sensor information. Will be nil if an error occurs.
 */
- (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andError: (NSError **) error;


/**
 Get all devices for the currently logged in user.
 
 This will fetch all the devices for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one device.
 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Array of devices. Each object will be an NSDictionary with the resulting device information. Will be nil if an error occurs.
 */
- (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andError: (NSError **) error;


/**
 Add sensor to a device. 
 
 This will create a device if it doesnt exist yet. This is the only way to create a new device. A device is uniquely identified by a device ID or by a name and UUID. This method will use the device ID as stored in the commonsense server. There is a twin method available that takes a name and UUID instead if the device ID is not available. 
 
 @param csSensorID		CommonSense sensor ID for the sensor. Cannot be empty.
 @param	csDeviceID		CommonSense device ID for the device. Cannot be empty. 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Whether or not the sensor was successfully added to the device.
 */
- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSessionID: (NSString *) sessionID andError: (NSError **) error;

/**
 Add sensor to a device.
 
 This will create a device if it doesnt exist yet. This is the only way to create a new device. A device is uniquely identified by a device ID or by a name and UUID. This method will use the name and UUID. There is a twin method available that takes a device ID. If the device ID is available this is the preferred method to use.
 
 @warning iOS does not provide consistent UUIDs anymore. Whenever an app is deinstalled and later reinstalled on the same device, the UUID retrieved from iOS might be different. This might cause a new device to be created in the backend when using this method to add a sensor to a device.
 
 @param csSensorID		CommonSense sensor ID for the sensor. Cannot be empty.
 @param	name			Unique name for the device. Cannot be empty.
 @param	UUID			UUID for the device. Cannot be empty.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Whether or not the sensor was successfully added to the device.
 */
- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithType: (NSString *) deviceType andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andError: (NSError **) error;



#pragma mark Data
/**
 @name Data
 */


/** 
 Upload sensor data to commonsense
 
 Data can be coming from multiple sensors.
 
 @param data			NSArray of datapoints. Each datapoint should be an NSDictionary with fields called "sensorID" (NSString), "value" (id), and "date" (NSDate *). These fields will be parsed into the correct form for uploading to commonsense.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				Whether or not the post of the data was succesfull.
 */
- (BOOL) postData: (NSArray *) data withSessionID: (NSString *) sessionID andError: (NSError **) error;


/**
 Download sensor data from commonsense from a certain date till now.
 
 @note The downloaded data will be passed as an NSArray * to the success callback method from which it can be further processed.
 
 @param csSensorID		Identifier of the sensor from CommonSense for which to download the data. Cannot be empty.
 @param fromDateDate	Date from which to download data. Datapoints after this date will be included in the download. Datapoints from before this date will be ignored. Cannot be nil.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. Cannot be nil.
 @result				NSArray with the resulting data. Each object is an NSDictionary with the data as provided by the backend. Will be nil if an error occured.
 */
- (NSArray *) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSessionID: (NSString *) sessionID andError: (NSError **) error;

@end;
