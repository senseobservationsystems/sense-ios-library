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
#import "CSSensorStore.h"
#import "NSData+GZIP.h"
#import "NSString+MD5Hash.h"


/* Some test values */
static NSString* testAppKeyStaging = @"wRgE7HZvhDsRKaRm6YwC3ESpIqqtakeg";
static NSString* newUserEmail_format = @"spam2+%f@sense-os.nl";
static NSString* testPassword = @"darkr";

static NSString* kUrlBaseURL = @"https://api.sense-os.nl";
static NSString* kUrlBaseURLLive = @"https://api.sense-os.nl";
static NSString* kUrlBaseURLStaging = @"http://api.staging.sense-os.nl";
static NSString* kUrlAuthentication= @"https://auth-api.sense-os.nl/v1/login";
static NSString* kUrlAuthenticationLive= @"https://auth-api.sense-os.nl/v1/login";
static NSString* kUrlAuthenticationStaging= @"http://auth-api.staging.sense-os.nl/v1/login";

static const NSString* kUrlLogin					= @"login";
static const NSString* kUrlLogout                   = @"logout";
static const NSString* kUrlSensorDevice             = @"device";
static const NSString* kUrlSensors                  = @"sensors";
static const NSString* kUrlUsers                    = @"users";
static const NSString* kUrlUploadMultipleSensors    = @"sensors/data";
static const NSString* kUrlData                     = @"data";
static const NSString* kUrlDevices                  = @"devices";

static const NSString* kUrlJsonSuffix               = @".json";


@interface DSECommonSenseProxyTest : XCTestCase
@property NSString* applicationKey;

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
    
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
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
    
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
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
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
    int expectedNumOfSensors = 0;
    
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
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self flushDataAndBlock];
    
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
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];

    int expectedNumOfDevices = 1;
    
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");

    [self flushDataAndBlock];
    
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
    
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
    int expectedNumOfSensors = 0;
    //login
    NSString *sessionID = [proxy loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self flushDataAndBlock];
    
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
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
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    name = @"test1";
    displayName = @"test1";
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //get list of sensors and count
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
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
    
    NSError* error;
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [self registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    
    
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

- (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass withEmail:(NSString*) email error:(NSString**) error
{
    //prepare post
    NSMutableDictionary* userPost = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     user, @"username",
                                     [pass MD5Hash], @"password",
                                     nil];
    if (email)
        [userPost setValue:email forKey:@"email"];
    else
        [userPost setValue:user forKey:@"email"];
    //encapsulate in "user"
    NSDictionary* post = [NSDictionary dictionaryWithObjectsAndKeys:
                          userPost, @"user",
                          nil];
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:&jsonError];
    NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSURL* url = [self makeUrlFor:@"users"];
    NSData* contents;
    NSHTTPURLResponse* response = [self doRequestTo:url method:@"POST" input:json output:&contents cookie:nil];
    BOOL didSucceed = YES;
    //check response code
    if ([response statusCode] != 201)
    {
        didSucceed = NO;
        NSLog(@"Couldn't register user.");
        NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
        NSLog(@"Responded: %@", responded);
        //interpret json response to set error
        NSError *jsonError = nil;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&jsonError];
        *error = [NSString stringWithFormat:@"%@", [jsonContents valueForKey:@"error"]];
    }
    return didSucceed;
}

- (void) flushDataAndBlock {
    [[CSSensorStore sharedSensorStore] forceDataFlushAndBlock];
}

///Creates the url using CommonSense.plist
- (NSURL*) makeUrlFor:(const NSString*) action
{
    return [self makeUrlFor:action append:@""];
}

- (NSURL*) makeUrlFor:(const NSString*) action append:(NSString*) appendix
{
    NSString* url = [NSString stringWithFormat: @"%@/%@%@%@",
                     kUrlBaseURLStaging,
                     action,
                     kUrlJsonSuffix,
                     appendix];
    
    return [NSURL URLWithString:url];
}

- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie {
    NSError* error;
    return [self doRequestTo:url method:method input:input output:output cookie:cookie error:&error];
}

- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie error:(NSError **) error
{
    NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:30];
    //set method method
    [urlRequest setHTTPMethod:method];
    
    //Cookie
    if (cookie != nil)
        [urlRequest setValue:cookie forHTTPHeaderField:@"cookie"];
    if (self.applicationKey != nil)
        [urlRequest setValue:self.applicationKey forHTTPHeaderField:@"APPLICATION-KEY"];
    //Accept compressed response
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    if (input != nil)
    {
        //Talking JSON
        [urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
        const char* bytes = [input UTF8String];
        NSData * body = [NSData dataWithBytes:bytes length: strlen(bytes)];
        //compress the body
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        [urlRequest setHTTPBody:[body gzippedData]];
        //[urlRequest setHTTPBody:body];
    }
    
    //connect
    NSHTTPURLResponse* response=nil;
    NSData* responseData;
    
    //Synchronous request
    responseData = [NSURLConnection sendSynchronousRequest:urlRequest
                                         returningResponse:&response
                                                     error:error];
    
    //don't handle errors in the request, just log them
    if (*error != nil) {
        NSLog(@"Error during request \'%@\': %@",	[urlRequest description] ,	*error);
        NSLog(@"Error description: \'%@\'.", [*error description] );
        NSLog(@"Error userInfo: \'%@\'.", [*error userInfo] );
        NSLog(@"Error failure reason: \'%@\'.", [*error localizedFailureReason] );
        NSLog(@"Error recovery options reason: \'%@\'.", [*error localizedRecoveryOptions] );
        NSLog(@"Error recovery suggestion: \'%@\'.", [*error localizedRecoverySuggestion] );
    }
    
    //log response
    if (response) {
        NSLog(@"%@ \"%@\" responded with status code %ld", method, url, (long)[response statusCode]);
        if (response.statusCode < 200 || response.statusCode >= 300) {
            NSLog(@"Sent: %@", input);
            NSLog(@"Received: %@", [[NSString alloc] initWithBytes:responseData.bytes length:responseData.length encoding:NSUTF8StringEncoding]);
        }
    }
    
    if (output != nil)
    {
        *output = responseData;
    }
    
    return response;
}

@end
