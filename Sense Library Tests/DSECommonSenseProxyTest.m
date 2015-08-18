//
//  DSECommonSenseProxyTest.m
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DSECommonSenseProxy.h"
#import "CSSensePlatform.h"

/* Some test values */
static NSString* testAppKey = @"wRgE7HZvhDsRKaRm6YwC3ESpIqqtakeg";
static NSString* testUser = @"pim+brightrblah@sense-os.nl";
static NSString* testPassword = @"darkr";


@interface DSECommonSenseProxyTest : XCTestCase

@end

@implementation DSECommonSenseProxyTest {
	DSECommonSenseProxy *proxy;
}

- (void)setUp {
	[super setUp];
	
	//Setup CommonSenseProxy for staging
	proxy = [[DSECommonSenseProxy alloc] initAndUseLiveServer:NO withAppKey:testAppKey];
	
}

- (void)tearDown {
	[super tearDown];
}

#pragma mark *User*

#pragma mark loginUser

- (void)testLoginWithValidUsernameAndPassword {
	
	NSError *error;
	NSString *sessionID = [proxy loginUser:testUser	andPassword:testPassword andError:&error];

	XCTAssertNil(error, @"Error is not nil; an error must have occured");
	XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
	XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
	
	sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
	
	XCTAssertNil(error, @"Error is not nil; an error must have occured");
	XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
	XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
}


- (void)testLoginWithValidUsernameAndInvalidPassword {
	
	NSError *error;
	NSString *sessionID = [proxy loginUser:testUser	andPassword:@"" andError:&error];
	
	XCTAssertNotNil(error, @"Error is nil; the login must have succeeded");
	XCTAssert(error.code >= 300, @"Errorcode is not representing an error");
	XCTAssertNil(sessionID, @"Session ID is not nil; the login must have succeeded");
	
	sessionID = [proxy loginUser:testUser andPassword:nil andError:&error];
	
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
	
	sessionID = [proxy loginUser:nil andPassword:testPassword andError:&error];
	
	XCTAssertNotNil(error, @"Error is nil; the login must have succeeded");
	XCTAssert(error.code >= 300, @"Errorcode is not representing an error");
	XCTAssertNil(sessionID, @"Session ID is not nil; the login must have succeeded");
}


#pragma mark logoutCurrentUserWIthSessionID

- (void) testLogoutWithValidSessionID {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    NSError *error;
    bool isSuccessful = [proxy logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    
    //Let me login again, so that I can log back out again!
    sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    isSuccessful = [proxy logoutCurrentUserWithSessionID:sessionID andError:nil];
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
}

- (void) testLogoutWithInvalidSessionID {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSString *invalidSessionID = @"VeryInvalidSessionID";
    //logout with INVALID sessionID
    NSError *error;
    bool isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have succeeded");
    XCTAssertFalse(isSuccessful, @"The logout was successful with invalid SessionID.");
  
    
    //Let me login again, so that I can log back out again!
    sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    //logout with INVALID sessionID
    isSuccessful = [proxy logoutCurrentUserWithSessionID:invalidSessionID andError:nil];
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

#pragma mark *Data*

#pragma mark createSensor, getSensors, getDevices

- (void) testCreateSensorAndGetSensor {

    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    //make sure that there is no sensor yet
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, 0, "There is already more than one sensor stored.");
    
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"string", @"test",
                            nil];
    NSString* dataStructure = @"";//[NSJSONSerialization dataWithJSONObject:format options:0 error:nil];
    
    //create a sensor
    error = nil;
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    
    //get list of sensors and count
    [self createSensorWithSufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyName {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDisplayName {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    
    [self createSensorWithSufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDeviceType {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    
    //-- device type
    
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDataType {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    
    //-- data type
    [self createSensorWithInsufficientParams:sessionID dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}

- (void) testCreateSensorWithEmptyDataStructure {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
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
    
    //-- session ID - mandatory!
    
    [self createSensorWithInsufficientParams:@"veryInvalidSessionID" dataStructure:dataStructure dataType:dataType deviceType:deviceType displayName:displayName name:name];
}




- (void) testCreateMultipleSensorsAndGetMultipleSensors {
    
    //login
    NSString *sessionID = [proxy loginUser:testUser andPassword:testPassword andError:nil];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    NSError* error;
    
    NSString* name = @"test";
    NSString* displayName = @"test";
    NSString* deviceType = @"deviceType";
    NSString* dataType = kCSDATA_TYPE_JSON;
    NSString* dataStructure = @"";
    
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];

}


#pragma mark helper functions

- (void)createSensorWithInsufficientParams:(NSString *)sessionID dataStructure:(NSString *)dataStructure dataType:(NSString *)dataType deviceType:(NSString *)deviceType displayName:(NSString *)displayName name:(NSString *)name{
    NSError *error;
    error = nil;
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; createSensor must have succeeded");
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, 0, "The number of sensors is not 0.");
}

- (void)createSensorWithSufficientParams:(NSString *)sessionID dataStructure:(NSString *)dataStructure dataType:(NSString *)dataType deviceType:(NSString *)deviceType displayName:(NSString *)displayName name:(NSString *) name{
    NSError *error;
    error = nil;
    [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; An error must have occurred");
    
    //get list of sensors and count
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, 1, "The number of sensors is not 1.");
}


@end
