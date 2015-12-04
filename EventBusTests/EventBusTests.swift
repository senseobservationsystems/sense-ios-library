//
//  EventBusTests.swift
//  EventBusTests
//
//  Created by Tatsuya Kaneko on 04/12/15.
//
//

import XCTest
@testable import EventBus
import SwiftyJSON

class EventBusTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEventBus_postWithArguments() {
        //Arrange
        let expectation = expectationWithDescription("expect events")
        let args = ["key1": "well well",
                    "key2": 1]
        
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: { notification in
            let retrievedArgs = JSON(notification.userInfo!)
            XCTAssertEqual(JSON(args), retrievedArgs)
            expectation.fulfill()
        })
        //Act
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: args)
        waitForExpectationsWithTimeout(5, handler: nil);
    }
    
    func testEventBus_withTwoListner_bothCalled() {
        let expectation = expectationWithDescription("expect events")
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in
            XCTFail()
        })
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in
            expectation.fulfill()
            XCTAssert(true)
        })
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: nil)
        
        waitForExpectationsWithTimeout(5, handler: nil);
    }
    
    func testEventBus_removingOneListner_BothNotCalled() {
        let expectation = expectationWithDescription("expect events")
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in
            XCTFail()
        })
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in
            XCTFail()
        })
        EventBus.sharedInstance.remove(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self);
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in 
            expectation.fulfill()
        })
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: nil)
        waitForExpectationsWithTimeout(1, handler: nil);
    }
    
}
