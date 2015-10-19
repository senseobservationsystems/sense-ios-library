//
//  SensorDataProxyTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 15/10/15.
//
//

import XCTest
@testable import DSESwift
@testable import SwiftyJSON

class SensorDataProxyTests: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testRegistrationAndDelete(){
        accountUtils!.deleteUser()
    }
    
    
    //TODO: This is not working yet
    func testGetSensorProfiles(){
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do {
            let json = try proxy.getSensorProfiles()
            debugPrint(json)
        }catch{
            print(error)
        }
    }

    func testGetSensorsWithZeroSensors() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray!.count, 0)
        }catch{
            print(error)
        }
    }
    

    func testGetSensors() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyData()
            proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray!.count, 3)
        }catch{
            print(error)
        }
    }
    
    func testGetSensorsWithSourceName() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyData()
            proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try proxy.getSensors(sourceName1)
            XCTAssertEqual(resultArray!.count, 2)
        }catch{
            print(error)
        }
    }
    
    func testGetSensorsWithSourceNameAndSensorName() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyData()
            proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let result = try proxy.getSensor(sourceName1, sensorName1)
            XCTAssertEqual(result!["sensor_name"] as? String, sensorName1)
        }catch{
            print(error)
        }
    }
    
    func testUpdateSensor() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            // check the sensor is added.
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray!.count, 1)
            
            // update meta
            let meta = ["Doge": "Wow, MUCH ACCELERATION! VERY HORSEPOWER!"]
            try proxy.updateSensor(sourceName: sourceName1, sensorName: sensorName1, meta: meta)
            
            let result = try proxy.getSensor(sourceName1, sensorName1)
            let retrievedMeta = result!["meta"] as? Dictionary<String, String>
            XCTAssertEqual(retrievedMeta!["Doge"], "Wow, MUCH ACCELERATION! VERY HORSEPOWER!")
            
        }catch{
            print(error)
        }
    }
    
    func testDeleteSensor() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            // check the sensor is added.
            var resultArray : Array<AnyObject>?
            resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray!.count, 2)
            
            // delete a sensor
            proxy.deleteSensor(sourceName1, sensorName1)
            resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray!.count, 1)
            
            // delete another sensor
            proxy.deleteSensor(sourceName2, sensorName2)
            resultArray = try proxy.getSensors()
            // Puff... aand it's gone
            XCTAssertEqual(resultArray!.count, 0)
        }catch{
            print(error)
        }
    }
    
    func testGetSensorData() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            let result = proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result!["data"]!.count, 5)
        }catch{
            print(error)
        }
    }
    
    func testPutSensorDataForMultipleSensors() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            let resultArray = try proxy.getSensors(sourceName1)
            XCTAssertEqual(resultArray!.count, 2)
            
            var result : Dictionary<String, AnyObject>?
            result = proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result!["data"]!.count, 5)
            
            result = proxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
            XCTAssertEqual(result!["data"]!.count, 5)
        }catch{
            print(error)
        }
    }
    
    func testDeleteSensorData() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName1, data: data1);
            
            let sensorName2 = "gyroscope"
            let data2 = getDummyData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            // Check that the sensors are added properly
            var resultArray: Array<AnyObject>?
            resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray!.count, 2)
            
            // delete a sensor
            proxy.deleteSensor(sourceName, sensorName1)
            resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray!.count, 1)
            
            // delete a sensor
            proxy.deleteSensor(sourceName, sensorName2)
            resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray!.count, 0)
        }catch{
            print(error)
        }
    }
    
    
    // MARK: helper function
    
    func getDummyData() -> Array<AnyObject>{
        let date = NSDate()
        let value = ["x": 4, "y": 5, "z": 6]
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Int(date.timeIntervalSince1970 * 1000) + (i * 1000)), "value": value]
            data.append(dataPoint)
        }
        return data
    }
}
