//
//  EventBusTests.swift
//  EventBusTests
//
//  Created by Tatsuya Kaneko on 04/12/15.
//
//

import XCTest
@testable import EventBus

class EventBusTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testEventBus_withOneListner() {
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered!")})
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: nil)
    }
    
    func testEventBus_withTwoListner_bothCalled() {
        let expectation = expectationWithDescription("expect events")
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered!")
            XCTFail()
        })
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered2!")
            expectation.fulfill()
            XCTAssert(true)
        })
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: nil)
        
        waitForExpectationsWithTimeout(5, handler: nil);
    }
    
    func testEventBus_removingOneListner_BothNotCalled() {
        let expectation = expectationWithDescription("expect events")
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered!")
            XCTFail()
        })
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered2!")
            XCTFail()
        })
        EventBus.sharedInstance.remove(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self);
        EventBus.sharedInstance.on(EventBusConstants.ACCELEROMETER_NEW_DATA, listener: self, block: {_ in print("event triggered3!")
            expectation.fulfill()
        })
        EventBus.sharedInstance.post(EventBusConstants.ACCELEROMETER_NEW_DATA, args: nil)
        waitForExpectationsWithTimeout(1, handler: nil);
    }
    
}
