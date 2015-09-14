//
//  CSSensePlatformTest.m
//  SensePlatform
//
//  Created by Joris Janssen on 03/07/15.
//
//

#import <XCTest/XCTest.h>
#import <SensePlatform/CSSensePlatform.h>

@interface CSSensePlatformTest : XCTestCase

@end

@implementation CSSensePlatformTest

- (void)setUp {
    [super setUp];
	//	[CSSensePlatform initialize];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void) testGetDataByDevice {
	//Remove all local data
	[CSSensePlatform removeLocalData];

	//Add data from 2 different devices and 2 different deviceTypes, using dateByAdding.. to ensure that these will never have the same time.
	[CSSensePlatform addDataPointForSensor:@"sensorName" displayName:@"displayName" description:@"description" deviceType:@"deviceTypeA" deviceUUID:@"deviceA" dataType:@"dataType" stringValue:@"0" timestamp:[[NSDate date] dateByAddingTimeInterval:-5000]];
    [CSSensePlatform addDataPointForSensor:@"sensorName" displayName:@"displayName" description:@"description" deviceType:@"deviceTypeB" deviceUUID:@"deviceB" dataType:@"dataType" stringValue:@"0" timestamp:[[NSDate date] dateByAddingTimeInterval:-4000]];
    [CSSensePlatform addDataPointForSensor:@"sensorName" displayName:@"displayName" description:@"description" deviceType:@"deviceTypeB" deviceUUID:@"deviceB" dataType:@"dataType" stringValue:@"1" timestamp:[[NSDate date] dateByAddingTimeInterval:-3000]];
    [CSSensePlatform addDataPointForSensor:@"sensorName" displayName:@"displayName" description:@"description" deviceType:@"deviceTypeB" deviceUUID:@"deviceC" dataType:@"dataType" stringValue:@"1" timestamp:[[NSDate date] dateByAddingTimeInterval:-2000]];
    [CSSensePlatform addDataPointForSensor:@"sensorName" displayName:@"displayName" description:@"description" deviceType:@"deviceTypeC" deviceUUID:@"deviceA" dataType:@"dataType" stringValue:@"1" timestamp:[[NSDate date] dateByAddingTimeInterval:-1000]];

	//Get data and make sure right amount of data
	NSArray *resultDeviceA = [CSSensePlatform getLocalDataForSensor:@"sensorName" andDeviceType:@"deviceTypeA" from:[NSDate dateWithTimeIntervalSince1970:0] to:[NSDate date]];
	XCTAssertEqual(resultDeviceA.count, 1, @"Did not find exactly one datapoint for device type A.");
	
	NSArray *resultDeviceB = [CSSensePlatform getLocalDataForSensor:@"sensorName" andDeviceType:@"deviceTypeB" from:[NSDate dateWithTimeIntervalSince1970:0] to:[NSDate date]];
	XCTAssertEqual(resultDeviceB.count, 3, @"Did not find exactly 3 datapoints for device type B.");
	
	NSArray *resultTotal = [CSSensePlatform getLocalDataForSensor:@"sensorName" from:[NSDate dateWithTimeIntervalSince1970:0] to:[NSDate date]];
	XCTAssertEqual(resultTotal.count, 5, @"Did not find exactly 5 points for sensor independent of device type.");
}


@end
