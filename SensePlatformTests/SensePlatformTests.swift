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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitialization() {
        let expectation = expectationWithDescription("wait for success callback")
        let completeHandler = {expectation.fulfill()}
        
        CSSettings.sharedSettings().setSettingType(kCSSettingTypeGeneral, setting: kCSGeneralSettingUseStaging, value: kCSSettingYES, persistent: true)
        //setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUseStaging value:(enabled ? kCSSettingYES : kCSSettingNO) persistent:NO]
        
        CSSensePlatform.initializeWithApplicationKey("o4cbgFZjPPDA6GO32WipJBLnyazu8w4o")
        
        do{
            try CSSensePlatform.loginWithUser("Username", andPassword: "Password", completeHandler: completeHandler, failureHandler: {})
        }catch{
            print(error)
            XCTFail()
        }
        
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
