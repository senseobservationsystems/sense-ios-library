//
//  SensorTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 18/11/15.
//
//

import XCTest
@testable import DSESwift
import RealmSwift
import SwiftyJSON

class SensorTests: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    var config = DSEConfig()
    let userId = "testuser"
    let dataSyncer = DataSyncer()
    
    override func setUp() {
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test2"
        KeychainWrapper.setString(userId, forKey: KEYCHAIN_USERID)
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        registerAndLogin(accountUtils!)
        
        // set the config with CORRECT default values
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = DSEServer.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils!.sessionId)!
        
        do{
            try self.dataSyncer.setConfig(self.config)
        } catch {
            XCTFail("Failed in setup")
        }
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.userId, forKey: KEYCHAIN_USERID)
        
        do{
            try dataSyncer.downloadSensorProfiles()
        }catch{
            XCTFail("Failed in setup")
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInsertAndGetDataPoint_withCorrectDictionaryValue_insertDataPointToLocalDatabase() {
        do{
            // Arrange: Make sensor object.
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "accelerometer", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            let value = ["x-axis": 3, "y-axis": 4, "z-axis": 5]
            
            // Act: insert the datapiont
            try sensor.insertOrUpdateDataPoint(value: value, time: NSDate())
        
            // Assert: check if the value of the retrieved datapoint is the same as the original value
            let queryOptions = QueryOptions()
            let retrievedDataPoints = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(JSON(value), JSON(retrievedDataPoints[0].getValueInDictionary()))
        }catch{
            print(error)
            XCTFail("exception is captured. Abort the test.")
        }
    }
    
    func testInsertDataPoint_withInCorrectDictionaryValue_getIncorrectDataStructureException() {
        do{
            // Arrange: Make sensor object with incorrect data strucutre
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "accelerometer", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            let value = ["wrong-x-axis": 3, "wrong-y-axis": 4, "wrong-z-axis": 5]
            
            // Act: insert the datapiont
            try sensor.insertOrUpdateDataPoint(value: value, time: NSDate())
            
        }catch{
            // Assert: Check if correct exception is thrown
            print(error)
            XCTAssert(error as! DSEError == DSEError.IncorrectDataStructure)
        }
    }
    
    func testInsertDataPoint_withUnknownSensor_getInvalidSensorNameException() {
        do{
            // Arrange: Make sensor object with unknown sensor name
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "unknwonsensor", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            let value = ["x-axis": 3, "y-axis": 4, "z-axis": 5]
            
            // Act: insert the datapiont
            try sensor.insertOrUpdateDataPoint(value: value, time: NSDate())
            
            
        }catch{
            // Assert:
            print(error)
            XCTAssert(error as! DSEError == DSEError.InvalidSensorName)
        }
    }
    
    func testSetSensorConfig_updateConfig() {
        do{
            // Arrange: Make sensor object
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "accelerometer", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            // Act: insert the datapiont
            var newSensorConfig = SensorConfig()
            newSensorConfig.downloadEnabled = false
            newSensorConfig.uploadEnabled = false
            newSensorConfig.persist = false
            newSensorConfig.meta = ["key":"value"]
            try sensor.setSensorConfig(newSensorConfig)
            
            // Assert: check the new configs
            XCTAssertEqual(sensor.persistLocally, newSensorConfig.persist)
            XCTAssertEqual(sensor.remoteDownloadEnabled, newSensorConfig.downloadEnabled)
            XCTAssertEqual(sensor.remoteUploadEnabled, newSensorConfig.uploadEnabled)
            XCTAssertEqual(JSON(sensor.meta), JSON(newSensorConfig.meta))
            
        }catch{
            XCTFail("Exception was captured. Abort the test")
        }
    }

    func testDeleteDataPoints_deleteDataPointsFromLocal_addDeletionRequest() {
        do{
            // Arrange: Make sensor object and add data points
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "accelerometer", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            let value = ["x-axis": 3, "y-axis": 4, "z-axis": 5]
            let time = NSDate()
            try sensor.insertOrUpdateDataPoint(value: value,time: time)
            
            // Act: call delete
            try sensor.deleteDataPoints(endTime:time.dateByAddingTimeInterval(0.1))
            
            // Assert: check if the datapoints are removed from local and deletion request is created for the datapoints
            let queryOptions = QueryOptions()
            let retrievedDataPoints = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(retrievedDataPoints.count, 0)
            let deletionRequests = DatabaseHandler.getDataDeletionRequests()
            XCTAssertEqual(deletionRequests.count, 1)
            XCTAssertEqualWithAccuracy(time.timeIntervalSince1970, (deletionRequests[0].endTime?.timeIntervalSince1970)!, accuracy:1.0)
            
        }catch{
            XCTFail("Exception was captured. Abort the test")
        }
    }
}
