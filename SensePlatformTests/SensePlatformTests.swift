//
//  SensePlatformTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 24/12/15.
//
//

import Foundation

import XCTest
@testable import SensePlatform
@testable import DSESwift

class SensePlatformTests: XCTestCase {
    
    let sourceName = "sense-library"
    
    override func setUp() {
        super.setUp()
        CSSettings.sharedSettings().setSettingType(kCSSettingTypeGeneral, setting: kCSGeneralSettingUseStaging, value: kCSSettingYES)
        self.loginSensePlatform()
    }
    
    override func tearDown() {
        print("----teardown----")
        super.tearDown()
    }
    
    func testAddDataPoint_TimeActive(){
        let sensorName = "time_active"
        // Act: Add a datapoint for time active
        CSSensePlatform.addDataPointForSensor(sensorName, displayName: "", description: "", dataType: kCSDATA_TYPE_FLOAT, stringValue: "0.00000000000000", timestamp: NSDate())
        
        // Assert: if DSE has the datapoint
        do{
            let sensor = try DataStorageEngine.getInstance().getSensor(sourceName, sensorName: sensorName)
            let queryOptions = QueryOptions()
            let dataPoints = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(dataPoints.count, 1)
            print(dataPoints[0].value)
            self.clearDataPoints(sensor)
        }catch{
            print(error)
            XCTFail()
        }
    }
    
    func testAddDataPoint_Sleep(){
        let sensorName = "sleep"
        //TODO: it would be nice if we can use the data from the actual module.
        let stringValue = "{\"end_date\" : 0.00000000000000,\"metadata\" : {\"core version\" : \"v1.12.0\",\"module version\" : \"1.7.1\",\"status\" : \"awake - device is carried\"},\"sleepTime\" : 0.00000000000000,\"start_date\" : 0}"
        // Act: Add a datapoint for time active
        CSSensePlatform.addDataPointForSensor(sensorName, displayName: "", description: "", dataType: kCSDATA_TYPE_JSON, stringValue: stringValue, timestamp: NSDate())
        
        // Assert: if DSE has the datapoint
        do{
            let sensor = try DataStorageEngine.getInstance().getSensor(sourceName, sensorName: sensorName)
            let queryOptions = QueryOptions()
            let dataPoints = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(dataPoints.count, 1)
            print(dataPoints[0].value)
            self.clearDataPoints(sensor)
        }catch{
            print(error)
            XCTFail()
        }
    }
    
    // MARK: helper class
    func clearDataPoints(sensor: Sensor){
        do{
            try sensor.deleteDataPoints()
        }catch{
            XCTFail("cleaning up data points failed. Next test might shows unexpected result.")
        }
    }
    
    
    func loginSensePlatform(){
        let expectation = expectationWithDescription("wait for login complete")
        let completeHandler = {expectation.fulfill()}
        CSSensePlatform.initializeWithApplicationKey("o4cbgFZjPPDA6GO32WipJBLnyazu8w4o")
        do{
            try CSSensePlatform.loginWithUser("Username", andPassword: "Password", completeHandler: completeHandler, failureHandler: {})
        }catch{
            print(error)
            XCTFail()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    
}
