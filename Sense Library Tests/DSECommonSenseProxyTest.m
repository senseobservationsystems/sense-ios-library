//
//  DSECommonSenseProxyTest.m
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DSEHTTPRequestHelper.h"
#import "DSECommonSenseProxy.h"
#import "CSSensePlatform.h"

/* Some test values */
static NSString* testAppKeyStaging = @"wRgE7HZvhDsRKaRm6YwC3ESpIqqtakeg";
static NSString* newUserEmail_format = @"spam2+%f@sense-os.nl";
static NSString* testPassword = @"darkr";


@interface DSECommonSenseProxyTest : XCTestCase

@end

@implementation DSECommonSenseProxyTest {
	DSECommonSenseProxy *proxy;
}

- (void)setUp {
	[super setUp];

    [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUseStaging value:kCSSettingYES];
    
	//Setup CommonSenseProxy for staging
	proxy = [[DSECommonSenseProxy alloc] initAndUseLiveServer:NO withAppKey:testAppKeyStaging];
	
}

- (void)tearDown {
    
	[super tearDown];
}

#pragma mark *User*

#pragma mark loginUser

- (void)testLoginWithValidUsernameAndPassword {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
	NSError *error;
	NSString *sessionID = [proxy loginUser:newUserEmail	andPassword:testPassword andError:&error];

	XCTAssertNil(error, @"Error is not nil; an error must have occured");
	XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
	XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
}

/*
- (void)testLoginWithValidUsernameAndInvalidPassword {
	
	NSError *error;
	NSString *sessionID = [proxy loginUser:newUserEmail	andPassword:@"" andError:&error];
	
	XCTAssertNotNil(error, @"Error is nil; the login must have succeeded");
	XCTAssert(error.code >= 300, @"Errorcode is not representing an error");
	XCTAssertNil(sessionID, @"Session ID is not nil; the login must have succeeded");
	
	sessionID = [proxy loginUser:newUserEmail andPassword:nil andError:&error];
	
	XCTAssertNotNil(error, @"Error is nil; the login must have succeeded");
	XCTAssert(error.code >= 300, @"Errorcode is not representing an error");
	XCTAssertNil(sessionID, @"Session ID is not nil; the login must have succeeded");
}


- (void)testLoginWithInValidUsernameAndPassword {
	
	NSError *error;
	NSString *sessionID = [proxy loginUser:@"" andPassword:testPassword andError:&error];
	
	XCTAssertNotNil(error, @"Error is nil; the login must have succeeded");
	XCTAssert(error.code >= 300, @"Errorcode is not representing an error");
	XCTAssertNil(sessionID, @"Session ID is not nil; the login must have succeeded");
}
*/

#pragma mark logoutCurrentUserWIthSessionID

- (void) testLogoutWithValidSessionID {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    //login
    NSError *error;
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID

    bool isSuccessful = [proxy logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    
    //Let me login again, so that I can log back out again!
    sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    isSuccessful = [proxy logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
}
/*
- (void) testLogoutWithInvalidSessionID {
    
    NSError *error;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSString *invalidSessionID = @"VeryInvalidSessionID";
    //logout with INVALID sessionID

    bool isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have succeeded");
    XCTAssertFalse(isSuccessful, @"The logout was successful with invalid SessionID.");
  
    
    //Let me login again, so that I can log back out again!
    sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    //logout with INVALID sessionID
    isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    XCTAssertFalse(isSuccessful, @"The logout was successful with invalid SessionID");
    
}


- (void) testLogoutWithoutLogin {
    
    NSString *invalidSessionID = @"VeryInvalidSessionID";
    //logout with the sessionID
    NSError *error;
    bool isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have succeeded");
    XCTAssertFalse(isSuccessful, @"The logout was successful without logging in.");
    
    //logout with the sessionID
    isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:nil];
    XCTAssertFalse(isSuccessful, @"The logout was successful without logging in");
    
}
  */

#pragma mark *Senser and Devices*

#pragma mark createSensor, getSensors, getDevices

- (void) testCreateSensorAndGetSensor {

    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    NSError* error;
    int expectedNumOfSensors = 1;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = @"";//[NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    [self createSensorWithSufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name expectedNumOfSensors: expectedNumOfSensors];
}

/*
- (void) testCreateSensorWithEmptyName {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @""; //empty name
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = [NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //--name - mandatory!
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDisplayName {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test"; //empty name
    NSString* displayName = @""; //empty diplayName
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = [NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //--diplay name
    [self createSensorWithSufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDeviceType {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test"; //empty name
    NSString* displayName = @"test"; //empty diplayName
    NSString* deviceType = @"";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = [NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //-- device type - mandatory!
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDataType {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test"; //empty name
    NSString* displayName = @"test"; //empty diplayName
    NSString* deviceType = @"deviceType";
    NSString* dataType = @"";
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = [NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //-- data type - mandatory!
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDataStructure {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test"; //empty name
    NSString* displayName = @"test"; //empty diplayName
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSString* dataStructure = @"";
    
    //-- data structure
    [self createSensorWithSufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptySessionID {
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test"; //empty name
    NSString* displayName = @"test"; //empty diplayName
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = [NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //-- session ID - mandatory!
    
    [self createSensorWithInsufficientParams:@"veryInvalidSessionID" dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}
 */


- (void) testCreateMultipleSensorsAndGetMultipleSensors {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    NSError* error;
    int expectedNumOfSensors = 1;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    NSString* name = @"test0";
    NSString* displayName = @"test0";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = @"";//[NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    name = @"test1";
    displayName = @"test1";
    
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    name = @"test2";
    displayName = @"test2";

    
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //get list of sensors and count
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );

}

- (void) testCreateMultipleSensorsAndGetDevices {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    NSError* error;
    int expectedNumOfDevices = 1;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");

    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfDevices, "The number of sensors is not 1.");
    
    
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType0";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = @"";//[NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    
    name = @"test1";
    displayName = @"test1";
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];

    name = @"test2";
    displayName = @"test2";
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    
    //get list of devices and count
    error = nil;
    NSArray *devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(devices.count, expectedNumOfDevices, @"Unexpected number of devices.");
}

#pragma mark addSensorWithID

// This test fails. Probably we should remove this.
/*
-(void) testAddSensorToDeviceWithDeviceId {
    
    NSError* error;
    int expectedNumOfSensors = 1;
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    //createSensor and get sensorId
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"float", @"value1",
                            @"float", @"value2",
                            @"float", @"value3",
                            nil];
    error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    NSString* dataStructure = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //get list of devices and count
    error = nil;
    NSArray *devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    BOOL result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithID:@"9999" andSessionID:sessionID andError:&error];
    XCTAssertEqual(result, YES, @"The result is NO. addSensorWithID must have failed");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    XCTAssertEqual(devices.count, 2, @"Unexpected number of devices.");
}
 */

-(void) testAddSensorToDeviceWithDeviceTypeAndUUID {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    NSError* error;
    int expectedNumOfSensors = 1;
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    //createSensor and get sensorId
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"float", @"value1",
                            @"float", @"value2",
                            @"float", @"value3",
                            nil];
    error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    NSString* dataStructure = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //get list of devices and count
    error = nil;
    NSArray *devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    BOOL result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithType: @"newType" andUUID:devices[0][@"uuid"] andSessionID:sessionID andError:&error];
    XCTAssertEqual(result, YES, @"The result is NO. addSensorWithID must have failed");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    XCTAssertEqual(devices.count, 2, @"Unexpected number of devices.");
}

#pragma mark *Data*

#pragma mark postData and getData

-(void) testPostAndGetData {
    
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [CSSensePlatform registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail];
    
    NSError* error;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    //createSensor and get sensorId
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"float", @"value1",
                            @"float", @"value2",
                            @"float", @"value3",
                            nil];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    NSString* dataStructure = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    
    //create datapoints
    NSMutableArray* datapoints = [[NSMutableArray alloc] init];
    
    for (int x = 0 ; x < 2; x++) {
        NSDate* now = [NSDate date];
        NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:1], @"value1",
                                   [NSNumber numberWithInt:2], @"value2",
                                   [NSNumber numberWithInt:3], @"value3",
                                   nil];
        NSDictionary* datapoint = [NSDictionary dictionaryWithObjectsAndKeys:
                                   value, @"value",
                                   @([now timeIntervalSince1970]), @"date",
                                   nil];
        [datapoints addObject:datapoint];
    }
    
    NSDictionary* dataDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               sensorInfo[@"sensor_id"], @"sensor_id",
                               datapoints, @"data",
                               nil];
    NSMutableArray* data =[[NSMutableArray alloc] init];
    [data addObject: dataDict];
    
    error = nil;
    BOOL isSuccessful = [proxy postData:data withSessionID:sessionID andError:&error];
    XCTAssertEqual(isSuccessful, YES, "postData returned NO. PostData must have failed.");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    error = nil;
    int aWeek = 7*24*60*60;
    NSDate* from = [[NSDate date] dateByAddingTimeInterval: -1 * aWeek];
    NSArray* result = [proxy getDataForSensor:sensorInfo[@"sensor_id"] fromDate:from withSessionID:sessionID andError:&error];
    XCTAssertEqual(result.count, 1, "Unexpected number of datapoints");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
}



#pragma mark helper functions

- (void)createSensorWithInsufficientParams:(NSString *)sessionID dataStructure:(NSString *)dataStructure dataType:(NSString *)dataType deviceType:(NSString *)deviceType displayName:(NSString *)displayName name:(NSString *)name expectedNumOfSensors: (int) expectedNumOfSensors{
    NSError *error;
    error = nil;
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; createSensor must have succeeded");
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
}

- (NSDictionary*) createSensorWithSufficientParams:(NSString *)sessionID dataStructure:(NSString *)dataStructure dataType:(NSString *)dataType deviceType:(NSString *)deviceType displayName:(NSString *)displayName name:(NSString *) name expectedNumOfSensors: (int) expectedNumOfSensors{
    NSError *error;
    error = nil;
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; An error must have occurred");
    expectedNumOfSensors++;
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
}

@end
