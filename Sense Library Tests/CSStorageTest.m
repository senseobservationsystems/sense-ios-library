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
    
    // cleanup database file so test always start with clean environment
    NSError *err;
    NSFileManager *fm = [NSFileManager defaultManager];
    err = nil;
    NSURL *url = [NSURL fileURLWithPath:dbPath];
    
    [fm removeItemAtPath:[url path] error:&err];
    
    if(err) {
        NSLog(@"File Manager: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    } else {
        NSLog(@"File %@ deleted.",dbPath);
    }
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
    NSDate* newStartDate = endDate;
    endDate = [newStartDate dateByAddingTimeInterval: 2.0];
    
    // this time we expect no datapoints because they do not fit in the correct time interval
    result = [storage getDataFromSensor:sensorName from:newStartDate to:endDate];
    XCTAssertEqual(result.count, 0, @"Data found in sensordata store despite using incorrect time interval");
}

/**
 * Tests the function for removing data before a certain time period
 */
- (void) testRemoveDataBeforeTime {
    
    //clear the db
    NSLog(@"Number of rows before trimming: %li", [storage getNumberOfRowsInTable:@"data"]);
    [storage trimLocalStorageTo:0.0];
    NSLog(@"Number of rows after trimming: %li", [storage getNumberOfRowsInTable:@"data"]);
    
    for( int i = 0; i < 1001; i++) { // add 1001 points
        
        NSString* value = [NSString stringWithFormat:@"Point %i",i];

        //put one datapoint in the database
        [storage storeSensor:sensorName description:@"testDescription" deviceType:@"testDeviceType" device:@"testDevice" dataType:@"testDataType" value:value timestamp:[[NSDate date] timeIntervalSince1970]];
        
        if( i%10000 == 0) {
            NSLog(@"%i Database size: %@, rows %li", i, [storage getDbSize], [storage getNumberOfRowsInTable:@"data"]); }
    }
    
    NSDate* endDate = [[NSDate date] dateByAddingTimeInterval: 2.0];
    
    [storage removeDataBeforeTime:endDate];
    NSArray* result = [storage getDataFromSensor:sensorName from:startDate to:endDate];
    XCTAssertEqual(result.count, 0, @"Data found in sensordata store despite deleting all data");
}


/**
 * Tests if the automatic management of space limitations of the db works well
 * Test might take a while to run as it creates a 100mb SQLite db
 */
-(void) testTrimLocalStorage {
    
    //clear the db
    NSLog(@"Number of rows before trimming: %li", [storage getNumberOfRowsInTable:@"data"]);
    [storage trimLocalStorageTo:0.0];
    NSLog(@"Number of rows after trimming: %li", [storage getNumberOfRowsInTable:@"data"]);
    
    //Fill up like crazy so that we have some decently sized db
    for( int i = 0; i < 1100000; i++) { // add 1000000 points

        NSString* value = [NSString stringWithFormat:@"Point %i",i];
        
        //put one datapoint in the database
        [storage storeSensor:sensorName description:@"testDescription" deviceType:@"testDeviceType" device:@"testDevice" dataType:@"testDataType" value:value timestamp:[[NSDate date] timeIntervalSince1970]];
       
        if( i%10000 == 0) {
            NSLog(@"%i Database size: %@, rows %li", i, [storage getDbSize], [storage getNumberOfRowsInTable:@"data"]); }
    }
    
    NSLog(@"Number of rows: %li", [storage getNumberOfRowsInTable:@"data"]);
    
    //If we get to here, that is just awesome
    XCTAssertTrue(true);
}

@end
