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
#import "CSSensorStore.h"
#import "AccountUtilsForTest.h"
#import "UIDevice+Hardware.h"


static enum SensorAttributes {
    None = 0,
    Sensor_Name,
    Sensor_DisplayName,
    Sensor_DeviceType,
    Sensor_DataType,
    Sensor_DataStructure
};


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
    proxy = [[DSECommonSenseProxy alloc] initForLiveServer:NO withAppKey:testAppKeyStaging];
}

- (void)tearDown {
    
	[super tearDown];
}

#pragma mark *User*

#pragma mark loginUser

- (void)testLoginWithValidUsernameAndPassword {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
	XCTAssertNil(error, @"Error is not nil; an error must have occured");
	XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
	XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
          
    [self deleteCurrentUser:sessionID];
}

- (void)testLoginWithWrongObjectForPassword {
    
    //Wrong object
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSDictionary* passwordWithWrongType = [NSDictionary dictionaryWithObjectsAndKeys:
                                           @"wrong password", @"password",
                                           nil];
    
    NSString *sessionID;
    NSException* expectedException;
    //try to login with wrong password, so that error will be used in the method
    @try{
        sessionID= [AccountUtilsForTest loginUser:newUserEmail andPassword:passwordWithWrongType andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:testPassword andError:&error];
    [self deleteCurrentUser:sessionID];
}

- (void)testLoginWithValidUsernameAndInvalidPassword {
	
	NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSString *sessionID;
    NSException* expectedException;
    @try {
        sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:@"" andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
	XCTAssertNotNil(expectedException, @"Exception is nil;");

    error = nil;
    @try {
        sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:nil andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
	XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:testPassword andError:&error];
    [self deleteCurrentUser:sessionID];
}


- (void)testLoginWithInvalidUsernameAndPassword {
	
	NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSString *sessionID;
    NSException* expectedException;
    @try {
        sessionID = [AccountUtilsForTest loginUser:@"" andPassword:testPassword andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    error = nil;
    @try {
        sessionID = [AccountUtilsForTest loginUser:nil andPassword:testPassword andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:testPassword andError:&error];
    [self deleteCurrentUser:sessionID];
}

#pragma mark logoutCurrentUserWIthSessionID

- (void) testLogoutWithValidSessionID {
    
    NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    error = nil;
    bool isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    //Let me login again, so that I can log back out again!
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    error = nil;
    isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail	andPassword:testPassword andError:&error];
    [self deleteCurrentUser:sessionID];
}

- (void) testLogoutWithInvalidSessionID {
    
    NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    error = nil;
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNil(error, @"Error is not nil; login must have failed");
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with INVALID sessionID
    NSString *invalidSessionID = @"VeryInvalidSessionID";
    error =nil;
    bool isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have succeeded");
    XCTAssertFalse(isSuccessful, @"The logout was successful with invalid SessionID.");

    [self deleteCurrentUser:sessionID];
}

- (void) testLogoutWithEmptySessionID {
    
    NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNil(error, @"Error is not nil; login must have failed");
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with EMPTY sessionID
    error = nil;
    bool isSuccessful;
    NSString *invalidSessionID = @"";
    NSException* expectedException;
    @try {
        isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:invalidSessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    [self deleteCurrentUser:sessionID];
}


- (void) testLogoutTwice {
    
    NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    error = nil;
    bool isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    //logout with the sessionID
    error = nil;
    isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have suceeded, where it should not.");
    XCTAssertFalse(isSuccessful, @"The logout was successful, where it should not.");
    
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    [self deleteCurrentUser:sessionID];
}

- (void) testLogoutWithOldSessionID {
    
    NSError *error;
    NSString* registrationError;
    NSString *newUserEmail;
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    error = nil;
    bool isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:sessionID andError:&error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssert(isSuccessful, @"The logout was unsuccessful.");
    
    NSString* oldSessionID = sessionID;
    //Let me login again, so that I can log back out again!
    error = nil;
    sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    XCTAssertGreaterThan(sessionID.length, 0, @"Invalid session ID");
    
    //logout with the sessionID
    error = nil;
    isSuccessful = [AccountUtilsForTest logoutCurrentUserWithSessionID:oldSessionID andError:&error];
    XCTAssertNotNil(error, @"Error is nil; logout must have suceeded, where it should not.");
    XCTAssertFalse(isSuccessful, @"The logout was successful, where it should not.");
    
    [self deleteCurrentUser:sessionID];
}

#pragma mark *Senser and Devices*

#pragma mark createSensor, getSensors, getDevices

- (void) testCreateSensorAndGetSensor {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}




- (void) testCreateSensorWithEmptyName {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;

    newUserEmail = [self registerANewUserForTest:registrationError];

    int expectedNumOfSensors = 0;

    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");

    [CSSensePlatform flushDataAndBlock];

    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");

    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_Name];

    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    NSException* expectedException;
    @try{
        sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");

    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}

- (void) testCreateSensorWithWrongObjectForName {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_Name];
    
    NSDictionary* nameWithWrongType = [NSDictionary dictionaryWithObjectsAndKeys:
                                       @"wrong type", @"name",
                                       nil];
    
    //post data
    error = nil;
    BOOL isSuccessful;
    NSException* expectedException;
    NSDictionary* sensorInfo;
    @try{
        //create a sensor with wrong object for name
        sensorInfo = [proxy createSensorWithName:nameWithWrongType andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
}



- (void) testCreateSensorWithEmptyDisplayName {
 
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_DisplayName];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}


- (void) testCreateSensorWithEmptyDeviceType {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_DeviceType];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    NSException* expectedException;
    @try{
        sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}


- (void) testCreateSensorWithEmptyDataType {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_DataType];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    NSException* expectedException;
    @try{
        sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}

- (void) testCreateSensorWithEmptyDataStructure {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_DataStructure];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );

    [self deleteCurrentUser:sessionID];
}

- (void) testCreateSensorWithEmptySessionID {
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;

    newUserEmail = [self registerANewUserForTest:registrationError];

    int expectedNumOfSensors = 0;

    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");

    [CSSensePlatform flushDataAndBlock];

    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");

    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:Sensor_DataType];

    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    NSException* expectedException;
    @try{
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:nil andError:&error];
    }
    @catch (NSException* e){
    expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");

    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}

- (void) testCreateSensorAndGetSensorWithEmptySessionID {
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    int expectedNumOfSensors = 0;
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [CSSensePlatform flushDataAndBlock];
    
    //make sure that there is no sensor yet
    error = nil;
    NSArray *sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertEqual(sensors.count, expectedNumOfSensors, "The number of sensors is not 1.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //check number of sensors
    error = nil;
    NSException* expectedException;
    @try {
        sensors = [proxy getSensorsWithSessionID: nil andError: &error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    [self deleteCurrentUser:sessionID];
}

- (void) testCreateMultipleSensorsAndGetMultipleSensors {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self flushDataAndBlock];
    
    NSArray *sensors;
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //create a sensor
    error = nil;
    name = @"test1";
    displayName = @"test1";
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //create a sensor
    error = nil;
    name = @"test2";
    displayName = @"test2";
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self deleteCurrentUser:sessionID];
}

- (void) testCreateMultipleSensorsAndGetDevices {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfDevices = 0;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");

    [self flushDataAndBlock];
    
    //check number of sensors
    error = nil;
    NSArray* sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary *sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //add a sensor to the device
    error = nil;
    NSDictionary* device = [DSECommonSenseProxyTest device];
    BOOL result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithType: @"type0" andUUID:device[@"uuid"] andSessionID:sessionID andError:&error];
    expectedNumOfDevices++;
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //get list of devices and count
    error = nil;
    NSArray *devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(devices.count, expectedNumOfDevices, @"Unexpected number of devices.");
    
    //create a sensor
    error = nil;
    name = @"test1";
    displayName = @"test1";
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //add a sensor to the device
    error = nil;
    device = [DSECommonSenseProxyTest device];
    result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithType: @"type1" andUUID:device[@"uuid"] andSessionID:sessionID andError:&error];
    expectedNumOfDevices++;
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //get list of devices and count
    error = nil;
    devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(devices.count, expectedNumOfDevices, @"Unexpected number of devices.");
    
    [self deleteCurrentUser:sessionID];
}

#pragma mark addSensorWithID

-(void) testAddSensorWithID {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self flushDataAndBlock];
    
    //check number of sensors
    error = nil;
    NSArray* sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary* sensorInfo;
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //add a sensor to the device
    error = nil;
    NSDictionary* device = [DSECommonSenseProxyTest device];
    BOOL result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithType: device[@"type"] andUUID:device[@"uuid"] andSessionID:sessionID andError:&error];
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //check number of devices
    error = nil;
    NSArray* devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    XCTAssertEqual(devices.count, 1, @"Unexpected number of devices.");
    
    //create a sensor
    error = nil;
    name = @"test1";
    displayName = @"test1";
    sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //add a sensor to the device
    error = nil;
    device = [DSECommonSenseProxyTest device];
    result = [proxy addSensorWithID:sensorInfo[@"sensor_id"] toDeviceWithType: device[@"type"] andUUID:device[@"uuid"] andSessionID:sessionID andError:&error];
    XCTAssertEqual(result, YES, @"The result is NO. addSensorWithID must have failed");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //check number of sensors
    error = nil;
    sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //check number of devices
    error = nil;
    devices = [proxy getDevicesWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    XCTAssertEqual(devices.count, 1, @"Unexpected number of devices.");
    
    [self deleteCurrentUser:sessionID];
}

#pragma mark *Data*

#pragma mark postData and getData

-(void) testPostAndGetData {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //check number of sensors
    error = nil;
    NSArray* sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //create a data to be posted
    NSMutableArray *data;
    data = [self createData:sensorInfo];
    
    //post data
    error = nil;
    BOOL isSuccessful = [proxy postData:data withSessionID:sessionID andError:&error];
    XCTAssertEqual(isSuccessful, YES, "postData returned NO. PostData must have failed.");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    //get data
    error = nil;
    int aWeek = 7*24*60*60;
    NSDate* from = [[NSDate date] dateByAddingTimeInterval: -1 * aWeek];
    NSArray* result = [proxy getDataForSensor:sensorInfo[@"sensor_id"] fromDate:from withSessionID:sessionID andError:&error];
    XCTAssertEqual(result.count, 1, "Unexpected number of datapoints");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    [self deleteCurrentUser:sessionID];
}

-(void) testPostAndGetDataWithWrongFormat {
    
    NSError* error;
    NSString* registrationError;
    NSString *newUserEmail;
    NSString *name;
    NSString *displayName;
    NSString *deviceType;
    NSString *dataType;
    NSString *dataStructure;
    int expectedNumOfSensors = 0;
    
    newUserEmail = [self registerANewUserForTest:registrationError];
    
    //login
    NSString *sessionID = [AccountUtilsForTest loginUser:newUserEmail andPassword:testPassword andError:&error];
    XCTAssertNotNil(sessionID, @"Session ID is nil; an error must have occured while logging in.");
    
    [self initializeSensorAttributes:error name_p:&name displayName_p:&displayName deviceType_p:&deviceType dataType_p:&dataType dataStructure_p:&dataStructure andEmptyAttribute:None];
    
    //create a sensor
    error = nil;
    NSDictionary* sensorInfo = [proxy createSensorWithName:name andDisplayName:displayName andDeviceType:deviceType andDataType:dataType andDataStructure:dataStructure andSessionID:sessionID andError:&error];
    expectedNumOfSensors++;
    
    //check number of sensors
    error = nil;
    NSArray* sensors = [proxy getSensorsWithSessionID: sessionID andError: &error];
    XCTAssertNil(error, @"Error is not nil; an error must have occured");
    XCTAssertEqual(sensors.count, expectedNumOfSensors, @"Unexpected number of sensors" );
    
    //create a dictionary as data
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                              sensorInfo[@"sensor_id"], @"sensor_id",
                              @"wrong data", @"data",
                              nil];
    
    //post data
    error = nil;
    BOOL isSuccessful;
    NSException* expectedException;
    @try{
        //post data with wrong object as data
        isSuccessful = [proxy postData:data withSessionID:sessionID andError:&error];
    }
    @catch (NSException* e){
        expectedException = e;
    }
    XCTAssertNotNil(expectedException, @"Exception is nil;");
    
    //get data
    error = nil;
    int aWeek = 7*24*60*60;
    NSDate* from = [[NSDate date] dateByAddingTimeInterval: -1 * aWeek];
    NSArray* result = [proxy getDataForSensor:sensorInfo[@"sensor_id"] fromDate:from withSessionID:sessionID andError:&error];
    XCTAssertEqual(result.count, 0, "Unexpected number of datapoints");
    XCTAssertNil(error, "The error is not nil. An error must have occured");
    
    [self deleteCurrentUser:sessionID];
}

#pragma mark helper functions



- (void)deleteCurrentUser:(NSString *)sessionID {
    //get user id of the current user
    NSError *error;
    error = nil;
    NSDictionary* currentUser = [AccountUtilsForTest getCurrentUserWithSessionID:sessionID andError:&error];
    NSString* userId = currentUser[@"id"];
    //delete
    error =nil;
    [AccountUtilsForTest deleteUserWithId:userId andSessionID:sessionID error:&error];
}



- (void) flushDataAndBlock {
    [[CSSensorStore sharedSensorStore] forceDataFlushAndBlock];
}




+ (NSDictionary*) device {
    NSString* type = [[UIDevice currentDevice] platformString];
    
    NSUUID* uuid = [[UIDevice currentDevice] identifierForVendor];
    //NSString* uuid = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
    NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
                            [uuid UUIDString], @"uuid",
                            type, @"type",
                            nil];
    return device;
}

- (NSString *)registerANewUserForTest:(NSString *)error {
    NSTimeInterval registrationTimestamp = [[NSDate date] timeIntervalSince1970];
    NSString* newUserEmail = [NSString stringWithFormat: newUserEmail_format, registrationTimestamp];
    [AccountUtilsForTest registerUser:newUserEmail withPassword:testPassword withEmail:newUserEmail error:&error];
    return newUserEmail;
}


- (void)initializeSensorAttributes:(NSError *)error name_p:(NSString **)name_p displayName_p:(NSString **)displayName_p deviceType_p:(NSString **)deviceType_p dataType_p:(NSString **)dataType_p dataStructure_p:(NSString **)dataStructure_p andEmptyAttribute: (enum SensorAttributes) emptyAttribute{
    //createSensor and get sensorId
    *name_p = emptyAttribute==Sensor_Name? nil :@"test";
    *displayName_p = (emptyAttribute==Sensor_DisplayName)? nil :@"test";
    *deviceType_p = (emptyAttribute==Sensor_DeviceType)? nil :@"deviceType";
    *dataType_p = (emptyAttribute==Sensor_DataType)? nil :kCSDATA_TYPE_JSON;
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"float", @"value1",
                            @"float", @"value2",
                            @"float", @"value3",
                            nil];
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    *dataStructure_p = (emptyAttribute==Sensor_DataStructure)? nil: [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSMutableArray *)createData:(NSDictionary *)sensorInfo {
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
    return data;
}


@end
