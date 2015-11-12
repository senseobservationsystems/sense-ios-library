//
//  SensorDataProxyTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 15/10/15.
//
//

import XCTest
@testable import DSESwift
import SwiftyJSON

class TestSensorDataProxy: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    let proxy = SensorDataProxy()
    var config = DSEConfig()
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // set the config with CORRECT default values
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        
        self.proxy.setConfig(self.config)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testRegistrationAndDelete() {
        XCTAssertEqual(accountUtils!.deleteUser(), true)
    }
    
    
    func testGetSensorProfiles(){
        do {
            let json = try proxy.getSensorProfiles()
            print(json[0])
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testGetSensorsWithZeroSensors() {
        do{
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 0)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensors() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 3)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorsWithSourceName() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try proxy.getSensors(sourceName1)
            XCTAssertEqual(resultArray.count, 2)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorsWithSourceNameAndSensorName() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let result = try proxy.getSensor(sourceName1, sensorName1)
            XCTAssertEqual(result["sensor_name"].stringValue, sensorName1)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSensor() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            // check the sensor is added.
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
            // update meta
            let meta = ["Doge": "Wow, MUCH ACCELERATION! VERY HORSEPOWER!"]
            try proxy.updateSensor(sourceName: sourceName1, sensorName: sensorName1, meta: meta)
            
            let result = try proxy.getSensor(sourceName1, sensorName1)
            XCTAssertEqual(result["meta"]["Doge"].stringValue, "Wow, MUCH ACCELERATION! VERY HORSEPOWER!")
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteSensor() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            // check the sensor is added.
            var resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 2)
            
            // delete a sensor
            try proxy.deleteSensor(sourceName1, sensorName1)
            resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
            // delete another sensor
            try proxy.deleteSensor(sourceName2, sensorName2)
            resultArray = try proxy.getSensors()
            // Puff... aand it's gone
            XCTAssertEqual(resultArray.count, 0)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorData() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            let result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorDataWithStartDate() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData(date: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-4*24*60*60)
            
            var result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 5)
            
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            
            result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 0)
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorDataWithEndDate() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData(date: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate()
            
            var result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 5)
            
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-2*24*60*60)
            
            result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 0)
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorDataWithLimit() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData(date: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            var result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            
            var queryOptions = QueryOptions()
            queryOptions.limit = 3
            
            result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 3)
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    
    func testPutSensorDataForMultipleSensors() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            let resultArray = try proxy.getSensors(sourceName1)
            XCTAssertEqual(resultArray.count, 2)
            
            var result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            
            result = try proxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
            XCTAssertEqual(result["data"].count, 5)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteSensorData() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName1, data: data1);
            
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            // == Check that the sensors are added properly
            // Sensors

            var resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            // SensorData
            var result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName2)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName1, startTime: nil, endTime: nil)
            resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 0)
            
            // delete the other sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName2, startTime: nil, endTime: nil)
            resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName2)
            XCTAssertEqual(result["data"].count, 0)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteSensorDataWithStartDate() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            let data = getDummyAccelerometerData(date: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            let sensorData = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
            
            let sensorsData = [sensorData]
            try proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            // == Check that the sensors are added properly
            // Sensors
            var resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 1)
            // SensorData
            var result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, startTime: NSDate().dateByAddingTimeInterval(-1*24*60*60), endTime: nil)
            resultArray = try proxy.getSensors(sourceName)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete the other sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, startTime: NSDate().dateByAddingTimeInterval(-3*24*60*60 - 60), endTime: nil)
            resultArray = try proxy.getSensors(sourceName)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 0)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteSensorDataWithEndDate() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            let data = getDummyAccelerometerData(date: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            let sensorData = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
            
            let sensorsData = [sensorData]
            try proxy.putSensorData(sensorsData)
            
            //TODO: remove the when the issue that inserting datapoints takes long time on the backend is solved
            NSThread.sleepForTimeInterval(5)
            
            // == Check that the sensors are added properly
            // Sensors
            var resultArray = try proxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 1)
            // SensorData
            var result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, endTime: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            resultArray = try proxy.getSensors(sourceName)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete the other sensor
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, endTime: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            resultArray = try proxy.getSensors(sourceName)
            result = try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 0)
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    // MARK: == Unsuccessful case 
    
    // MARK: Sensor does not exist yet
    
    func testGetSensorsWithNonExistingSensors() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            let resultArray = try proxy.getSensor(sourceName, sensorName)
            debugPrint(resultArray)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.SensorDoesNotExist)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    //TODO: revive when the backend can return an error when update is called on the sensor which does not exist yet
//    func testUpdateSensorsWithNonExistingSensors() {
//        do{
//            let sourceName = "aim-ios-sdk"
//            let sensorName = "accelerometer"
//            let meta = ["Doge": "Wow, MUCH ACCELERATION! VERY HORSEPOWER!"]
//            let result = try proxy.updateSensor(sourceName: sourceName, sensorName: sensorName, meta: meta)
//            debugPrint(result)
//        } catch let e as SensorDataProxy.ProxyError {
//            assert( e == SensorDataProxy.ProxyError.SensorDoesNotExistOrBadStructure )
//        } catch {
//            XCTFail("Wrong error")
//        }
//    }
    
    func testDeleteSensorsWithNonExistingSensors() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            try proxy.deleteSensor(sourceName, sensorName)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.SensorDoesNotExist )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testGetSensorDataWithNonExistingSensors() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            try proxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.SensorDoesNotExist )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testDeleteSensorDataWithNonExistingSensors() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            try proxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.SensorDoesNotExist )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    // MARK: Others

    // ## bad structure
    
    // putSensorData
    func testPutSensorWithBadStructure() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            let data = getDummyDataWithBadStructure()
            try proxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorDataForMultipleSensorsWithBadStructure() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyDataWithBadStructure()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    // ## invalidSensorName or source
    
    func testPutSensorWithInvalidSourceName() {
        do{
            let sourceName = "invalidSourceName"
            let sensorName = "accelerometer"
            let data = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorWithInvalidSensorName() {
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "invalidSensorName"
            let data = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorForMultipleSensorsWithInvalidSourceName() {
        do{
            let sourceName1 = "invalidSourceName"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorForMultipleSensorsWithInvalidSensorName() {
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "invalidSensorName"
            let data1 = getDummyAccelerometerData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSensorOrSourceOrBadStructure )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    // ## invalid limit
    
    func testGetSensorDataWithInvalidLimit(){
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            var queryOptions = QueryOptions()
            queryOptions.limit = 0
            
            let result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            debugPrint(result)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidQuery )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    // ## invalid start and end time
    func testGetSensorDataWithInvalidStartEndTime(){
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
    
            var queryOptions = QueryOptions()
            let now = NSDate()
            queryOptions.startTime = now
            queryOptions.endTime = now
            
            let result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            debugPrint(result)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidQuery )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testDeleteSensorDataWithInvalidStartEndTime(){
        do{
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
        
            let now = NSDate()
            try proxy.deleteSensorData(sourceName: sourceName1, sensorName: sensorName1, startTime: now, endTime: now)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidQuery)
        } catch {
            XCTFail("Wrong error")
        }
    }

    
    // MARK: Invalid sessionId
    
    func testGetSensorProfilesWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let json = try proxy.getSensorProfiles()
            debugPrint(json)
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorsWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testGetSensorsWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let json = try proxy.getSensors()
            print(json)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testGetSensorWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let json = try proxy.getSensor(sourceName1, sensorName1)
            print(json)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testGetSensorsWithSourceNameWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let json = try proxy.getSensors()
            print(json)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testUpdateSensorsWithInvalidSessionId(){
        let sourceName1 = "aim-ios-sdk"
        let sensorName1 = "accelerometer"
        let data1 = getDummyAccelerometerData()
        do{
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            // check the sensor is added.
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            // update meta
            let meta = ["Doge": "Wow, MUCH ACCELERATION! VERY HORSEPOWER!"]
            try proxy.updateSensor(sourceName: sourceName1, sensorName: sensorName1, meta: meta)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testDeleteSensorsWithInvalidSessionId(){
        let sourceName1 = "aim-ios-sdk"
        let sensorName1 = "accelerometer"
        let data1 = getDummyAccelerometerData()
        do{
            try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            // check the sensor is added.
            let resultArray = try proxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
        
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            // delete a sensor
            try proxy.deleteSensor(sourceName1, sensorName1)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testGetSensorDataWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            
            let result = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testDeleteSensorDataWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            try proxy.deleteSensorData(sourceName: "sourcename", sensorName: "sensorName", startTime: nil, endTime: nil)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testPutSensorDataForMultipleSensorsWithInvalidSessionId(){
        // invalidate the proxy session ID
        proxy.setSessionId("invalidSessionId")
        do {
            let sourceName1 = "aim-ios-sdk"
            let sensorName1 = "accelerometer"
            let data1 = getDummyAccelerometerData()
            let sensorData1 = SensorDataProxy.createSensorDataObject(sourceName: sourceName1, sensorName: sensorName1, data: data1);
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            let sensorData2 = SensorDataProxy.createSensorDataObject(sourceName: sourceName2, sensorName: sensorName2, data: data2);
            
            let sensorsData = [sensorData1, sensorData2]
            try proxy.putSensorData(sensorsData)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidSessionId )
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    
    // MARK: == helper functions
    func getDummyAccelerometerData(date date: NSDate? = NSDate()) -> Array<AnyObject>{
        let value = ["x-axis": 4, "y-axis": 5, "z-axis": 6]
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Int(date!.timeIntervalSince1970 * 1000) + (i * 1000)), "value": value]
            data.append(dataPoint)
        }
        return data
    }
    
    func getDummyTimeActiveData(date date: NSDate? = NSDate()) -> Array<AnyObject>{
        let value = 3
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Int(date!.timeIntervalSince1970 * 1000) + (i * 1000)), "value": value]
            data.append(dataPoint)
        }
        return data
    }
    
    func getDummyDataWithBadStructure() -> Array<AnyObject>{
        let time = NSDate()
        let value = ["invalidx": 4, "invalidy": 5, "invalidz": 6]
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Double(time.timeIntervalSince1970 * 1000.0) + Double((i * 1000))), "value": value]
            data.append(dataPoint)
        }
        return data
    }

}
