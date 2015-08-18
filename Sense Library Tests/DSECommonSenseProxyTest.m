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
@end
