//
//  Sense_Library_Tests.m
//  Sense Library Tests
//
//  Created by Joris Janssen on 06/01/15.
//
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface Sense_Library_Tests : XCTestCase

@end

@implementation Sense_Library_Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStoreData {
    
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
