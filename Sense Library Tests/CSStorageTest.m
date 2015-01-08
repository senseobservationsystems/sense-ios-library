//
//  CSStorageTest.m
//  SensePlatform
//
//  Created by Joris Janssen on 07/01/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "CSSensePlatform.h"
#import "CSSensorStore.h"
#import "CSStorage.h"



@interface CSStorageTest : XCTestCase

@end

@implementation CSStorageTest {
    CSStorage* storage;
    NSDate* startDate;
    NSString* sensorName;
}

- (void)setUp {
    [super setUp];

    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* dbPath =[rootPath stringByAppendingPathComponent:@"data.db"];
    
    storage = [[CSStorage alloc] initWithPath:dbPath];
    
    startDate = [NSDate date];
    sensorName = @"testSensor";
    
    //put one datapoint in the database
    [storage storeSensor:sensorName description:@"testDescription" deviceType:@"testDeviceType" device:@"testDevice" dataType:@"testDataType" value:@"somevalue" timestamp:[startDate timeIntervalSince1970]];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

/**
 * Tests the function for getting data in CSStorage
 */
- (void)testSensorDataPointsFromId {
    NSArray* result = [storage getSensorDataPointsFromId:0 limit:5];
//  NSLog(@"Number of rows is %i", result.count);
    XCTAssertGreaterThan(result.count, 0, @"No data found in sensordata store!");
    XCTAssertEqual(result.count, 1, @"Not one row found in sensordata store although only one point should have been added!");
}

/**
 * Tests the function for getting data from a sensor getDataFromSensor in CSStorage
 */
- (void) testGetDataFromSensor {

    NSDate* endDate = [startDate dateByAddingTimeInterval: 2.0];
    
    NSArray* result = [storage getDataFromSensor:sensorName from:startDate to:endDate];
    XCTAssertGreaterThan(result.count, 0, @"No data found in sensordata store!");
    XCTAssertEqual(result.count, 1, @"Not one row found in sensordata store although only one point should have been added!");
    
    //this time we expect no data points because we use a non existing sensor name
    result = [storage getDataFromSensor:@"nonExistingSensorName" from:startDate to:endDate];
    XCTAssertEqual(result.count, 0, @"Data found in sensordata store despite using non existing sensor name");
    
    //shifting the interval
    startDate = endDate;
    endDate = [startDate dateByAddingTimeInterval: 2.0];
    
    // this time we expect no datapoints because they do not fit in the correct time interval
    result = [storage getDataFromSensor:sensorName from:startDate to:endDate];
    XCTAssertEqual(result.count, 0, @"Data found in sensordata store despite using incorrect time interval");
}

@end
