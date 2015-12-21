//
//  SensePlatformTestss.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/12/15.
//
//

import XCTest
@testable import DSESwift

class SensePlatformTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        CSSettings.sharedSettings().setSettingType(kCSSettingTypeGeneral, setting:
        
        CSSensePlatform.initializeWithApplicationKey("o4cbgFZjPPDA6GO32WipJBLnyazu8w4o")
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testInitialization() {
        // Arange: set expectation and callback
        let expectation = expectationWithDescription("wait for success callback")
        let completeHandler = {expectation.fulfill()}

        // Act: Login
        do{
            try CSSensePlatform.loginWithUser("Username", andPassword: "Password", completeHandler: completeHandler, failureHandler: {})
        }catch{
            print(error)
            XCTFail()
        }
        
        // Assert: State of DSE
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
    func testAddDataPoint(){
        testInitialization()
        
        CSSensePlatform.addDataPointForSensor("time_active", displayName: "", description: "", dataType: kCSDATA_TYPE_FLOAT, stringValue: "0.00000000000000", timestamp: NSDate())
        
        do{
            let sensor = try DataStorageEngine.getInstance().getSensor("sense-library", sensorName: "time_active")
            let queryOptions = QueryOptions()
            let dataPoints = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(dataPoints.count, 1)
            print(dataPoints[0].value)
        }catch{
            print(error)
            XCTFail()
        }
    }
    
    func test(){
        print(NSNumberFormatter().numberFromString("0.0000000000"));
    }
    
}
