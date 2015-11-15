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
import OHHTTPStubs

class TestSensorDataProxy: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    var config = DSEConfig()
    
    let userId = "testuser"
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        let backendStringValue = "STAGING"
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // set the config with CORRECT default values
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId!, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey!,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.userId, forKey: KEYCHAIN_USERID)
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(backendStringValue, forKey: BACKEND_ENVIRONMENT_KEY)

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
            let json = try SensorDataProxy.getSensorProfiles()
            print(json[0])
        }catch{
            print( error )
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testGetSensorsWithZeroSensors() {
        do{
            let resultArray = try SensorDataProxy.getSensors()
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try SensorDataProxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try SensorDataProxy.getSensors()
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try SensorDataProxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let resultArray = try SensorDataProxy.getSensors(sourceName1)
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            let sourceName3 = "fitbit"
            let sensorName3 = "accelerometer"
            let data3 = getDummyAccelerometerData()
            try SensorDataProxy.putSensorData(sourceName: sourceName3, sensorName: sensorName3, data: data3)
            
            let result = try SensorDataProxy.getSensor(sourceName1, sensorName1)
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            // check the sensor is added.
            let resultArray = try SensorDataProxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
            // update meta
            let meta = ["Doge": "Wow, MUCH ACCELERATION! VERY HORSEPOWER!"]
            try SensorDataProxy.updateSensor(sourceName: sourceName1, sensorName: sensorName1, meta: meta)
            
            let result = try SensorDataProxy.getSensor(sourceName1, sensorName1)
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let sourceName2 = "aim-ios-sdk"
            let sensorName2 = "time_active"
            let data2 = getDummyTimeActiveData()
            try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
            
            // check the sensor is added.
            var resultArray = try SensorDataProxy.getSensors()
            XCTAssertEqual(resultArray.count, 2)
            
            // delete a sensor
            try SensorDataProxy.deleteSensor(sourceName1, sensorName1)
            resultArray = try SensorDataProxy.getSensors()
            XCTAssertEqual(resultArray.count, 1)
            
            // delete another sensor
            try SensorDataProxy.deleteSensor(sourceName2, sensorName2)
            resultArray = try SensorDataProxy.getSensors()
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            let result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
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
            let data1 = getDummyAccelerometerData(time: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-4*24*60*60)
            
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 5)
            
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            
            result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
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
            let data1 = getDummyAccelerometerData(time: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate()
            
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            XCTAssertEqual(result["data"].count, 5)
            
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-2*24*60*60)
            
            result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
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
            let data1 = getDummyAccelerometerData(time: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            
            var queryOptions = QueryOptions()
            queryOptions.limit = 3
            
            result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
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
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
            let resultArray = try SensorDataProxy.getSensors(sourceName1)
            XCTAssertEqual(resultArray.count, 2)
            
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            
            result = try SensorDataProxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
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
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
            // == Check that the sensors are added properly
            // Sensors

            var resultArray = try SensorDataProxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            // SensorData
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 5)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName2)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName1, startTime: nil, endTime: nil)
            resultArray = try SensorDataProxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName1)
            XCTAssertEqual(result["data"].count, 0)
            
            // delete the other sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName2, startTime: nil, endTime: nil)
            resultArray = try SensorDataProxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 2)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName2)
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
            let data = getDummyAccelerometerData(time: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            let sensorData = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
            
            let sensorsData = [sensorData]
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
            // == Check that the sensors are added properly
            // Sensors
            var resultArray = try SensorDataProxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 1)
            // SensorData
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, startTime: NSDate().dateByAddingTimeInterval(-1*24*60*60), endTime: nil)
            resultArray = try SensorDataProxy.getSensors(sourceName)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete the other sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, startTime: NSDate().dateByAddingTimeInterval(-3*24*60*60 - 60), endTime: nil)
            resultArray = try SensorDataProxy.getSensors(sourceName)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
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
            let data = getDummyAccelerometerData(time: NSDate().dateByAddingTimeInterval(-1*24*60*60))
            let sensorData = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
            
            let sensorsData = [sensorData]
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
            // == Check that the sensors are added properly
            // Sensors
            var resultArray = try SensorDataProxy.getSensors(sourceName)
            XCTAssertEqual(resultArray.count, 1)
            // SensorData
            var result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete a sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, endTime: NSDate().dateByAddingTimeInterval(-3*24*60*60))
            resultArray = try SensorDataProxy.getSensors(sourceName)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            XCTAssertEqual(result["data"].count, 5)
            
            // delete the other sensor
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName, endTime: NSDate().dateByAddingTimeInterval(-1*23*60*60))
            resultArray = try SensorDataProxy.getSensors(sourceName)
            result = try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
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
            let resultArray = try SensorDataProxy.getSensor(sourceName, sensorName)
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
//            let result = try SensorDataProxy.updateSensor(sourceName: sourceName, sensorName: sensorName, meta: meta)
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
            try SensorDataProxy.deleteSensor(sourceName, sensorName)
            
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
            try SensorDataProxy.getSensorData(sourceName: sourceName, sensorName: sensorName)
            
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
            try SensorDataProxy.deleteSensorData(sourceName: sourceName, sensorName: sensorName)
            
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
            try SensorDataProxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
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
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
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
            try SensorDataProxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
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
            try SensorDataProxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data)
            
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
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
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
            try SensorDataProxy.putSensorData(JSON(sensorsData))
            
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
            
            var queryOptions = QueryOptions()
            queryOptions.limit = 0
            
            let result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
    
            var queryOptions = QueryOptions()
            let now = NSDate()
            queryOptions.startTime = now
            queryOptions.endTime = now
            
            let result = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
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
            try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)
        
            let now = NSDate()
            try SensorDataProxy.deleteSensorData(sourceName: sourceName1, sensorName: sensorName1, startTime: now, endTime: now)
            
            XCTFail("An error should have thrown, but no error was thrown")
            
        } catch let e as SensorDataProxy.ProxyError {
            assert( e == SensorDataProxy.ProxyError.InvalidQuery)
        } catch {
            XCTFail("Wrong error")
        }
    }

    


}
