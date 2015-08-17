//
//  DSECommonSenseProxy.h
//  SensePlatform
//
//  Created by Joris Janssen on 16/08/15.
//
//

#import <Foundation/Foundation.h>

/**
 *	The DSECommonSenseProxy class consists of static methods that wrap the API.
 
	Only API calls there are necessary for the DataStorageEngine have been implemented here. All calls are made in a synchronous manner. It is up to the user to either call the API in a synchronous or asynchronous manner.
	
	The DSECommonSenseProxy class does not now about DataStorageEngine concepts, it simply wraps the API that is available for CommonSense. Any translations between concepts in the DataStorageEngine and CommonSense should be made by other objects (most notably the difference between Source and Device). 
 
	The DSECommonSenseProxy uses a Session ID and Application Key to get authorized for API access. These parameters are not managed by the DSECommonSenseProxy but should instead by provided as a parameter when calling the method in the proxy. 
 
	There is no need to instantiate the DSECommonSenseProxy. It is simply a collection of static methods and is stateless.
 */
@interface DSECommonSenseProxy : NSObject


#pragma mark User
/**
 @name Users
 */

/**
 Login a user
 
 @note If a user is already logged in this call will fail. That user should be logged out first before a new login attempt can be made. The failureCallback will be called in that case.
 
 @param username		A user account in commonsense is uniquely identified by a username.
 @param password		A password in commonsense does not have any specific requirements. It will be MD5 hashed before sending to the server so the user does not have to provide a hashed password.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @return				Session ID. Will be nil if the call fails.
 */
+ (NSString *) loginUser: (NSString *) username andPassword: (NSString *) password andAppKey: (NSString *) appKey andError: (NSError **) error;

/**
 Logout the currently logged in user.
 
 @param sessionID		The sessionID of the user to logout. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @return				Whether or not the logout finished succesfully.
 */
+ (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;


#pragma mark Sensors and Devices
/**
 @name Sensors and Devices (DSESource backend equivalent)
*/


/**
 Create a new sensor in the commonsense backend
 
 Each sensor in commonsense is uniquely identified by a name and devicetype combination. If this combination already exists in the commonsense backend this call will fail.
 
 @param name			Name of the sensor to create. This will be used to identify the sensor.
 @param displayName		Extra field to make sensor name more readable if necessary when displaying it.
 @param deviceType		Name of the device type the sensor belongs to.
 @param dataType		Type of data that the sensor stores.
 @param dataStructure	Structure of the data in the data; can be used to specify the JSON structure in the sensor.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Dictionary with the information of the created sensor.
 */
+ (NSDictionary *) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;


/**
 Get all sensors for the currently logged in user.
 
 This will fetch all the sensors for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one sensor.
 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Array of sensors. Each object will be an NSDictionary with the resulting sensor information. Will be nil if an error occurs.
 */
+ (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;


/**
 Get all devices for the currently logged in user.
 
 This will fetch all the devices for the current user and pass them on to the success callback as an NSArray. Each element in the array will contain an NSDictionary with data from one device.
 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Array of devices. Each object will be an NSDictionary with the resulting device information. Will be nil if an error occurs.
 */
+ (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;


/**
 Add sensor to a device. 
 
 This will create a device if it doesnt exist yet. This is the only way to create a new device. A device is uniquely identified by a device ID or by a name and UUID. This method will use the device ID as stored in the commonsense server. There is a twin method available that takes a name and UUID instead if the device ID is not available. 
 
 @param csSensorID		CommonSense sensor ID for the sensor. Cannot be empty.
 @param	csDeviceID		CommonSense device ID for the device. Cannot be empty. 
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Whether or not the sensor was successfully added to the device.
 */
+ (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;

/**
 Add sensor to a device.
 
 This will create a device if it doesnt exist yet. This is the only way to create a new device. A device is uniquely identified by a device ID or by a name and UUID. This method will use the name and UUID. There is a twin method available that takes a device ID. If the device ID is available this is the preferred method to use.
 
 @warning iOS does not provide consistent UUIDs anymore. Whenever an app is deinstalled and later reinstalled on the same device, the UUID retrieved from iOS might be different. This might cause a new device to be created in the backend when using this method to add a sensor to a device.
 
 @param csSensorID		CommonSense sensor ID for the sensor. Cannot be empty.
 @param	name			Unique name for the device. Cannot be empty.
 @param	UUID			UUID for the device. Cannot be empty.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Whether or not the sensor was successfully added to the device.
 */
+ (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithName: (NSString *) csDeviceName andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;



#pragma mark Data
/**
 @name Data
 */


/** 
 Upload sensor data to commonsense
 
 Data can be coming from multiple sensors.
 
 @param data			NSArray of datapoints. Each datapoint should be an NSDictionary with fields called "sensorID" (NSString), "value" (id), and "date" (NSDate *). These fields will be parsed into the correct form for uploading to commonsense.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				Whether or not the post of the data was succesfull.
 */
+ (BOOL) postData: (NSArray *) data withSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;


/**
 Download sensor data from commonsense from a certain date till now.
 
 @note The downloaded data will be passed as an NSArray * to the success callback method from which it can be further processed.
 
 @param csSensorID		Identifier of the sensor from CommonSense for which to download the data.
 @param fromDateDate	Date from which to download data. Datapoints after this date will be included in the download. Datapoints from before this date will be ignored.
 @param sessionID		The sessionID of the current user. Cannot be empty.
 @param appKey			An application key that identifies the application to the commonsense server. Cannot be empty.
 @param error			Reference to an NSError object that will contain error information if an error occurs. If nil, will be ignored.
 @result				NSArray with the resulting data. Each object is an NSDictionary with the data as provided by the backend. Will be nil if an error occured.
 */
+ (NSArray *) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSessionID: (NSString *) sessionID andAppKey: (NSString *) appKey andError: (NSError **) error;
@end;
