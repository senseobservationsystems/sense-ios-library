//
//  DataSyncerTest.swift
//  SensePlatform
//
//  Created by Fei on 22/10/15.
//
//

import XCTest
@testable import DSESwift
import RealmSwift
import SwiftyJSON
import PromiseKit

class TestDataSyncer: XCTestCase{
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
    let userId = "testuser"
    
    let sourceName1 = "aim-ios-sdk"
    let sensorName1 = "accelerometer"
    
    let sourceName2 = "aim-ios-sdk"
    let sensorName2 = "time_active"
    
    let sourceName3 = "fitbit"
    let sensorName3 = "time_active"
    
    let dataSyncer = DataSyncer()
    var config = DSEConfig()
    
    override func setUp() {
        super.setUp()
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        registerAndLogin()
        
        
        // set the config with CORRECT default values
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        
        do{
            try self.dataSyncer.setConfig(self.config)
        } catch {
            XCTFail("Fail in setup")
        }
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId!, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey!,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.userId, forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultValuesForSyncRateAndPersistentPeriod() {
        
        let expectedSyncRate: Double = 30 * 60
        let expectedPersistentPeriod: Double = 30 * 24 * 60 * 60
        XCTAssertEqual(self.dataSyncer.syncRate, expectedSyncRate)
        XCTAssertEqual(self.dataSyncer.persistentPeriod, expectedPersistentPeriod)
    }
    
    func testInitialize() {
            let response = self.expectationWithDescription("wait for promises")
            
            firstly({
                return try self.dataSyncer.downloadSensorProfiles()
            }).then({
                let profiles = try DatabaseHandler.getSensorProfiles()
                XCTAssertEqual(profiles.count, 16)
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
    }
    
    func testProcessDeletionRequest() {
        do{
            let response = self.expectationWithDescription("wait for promises")
            
            try populateRemoteDatabase()
            try assertDataPointsInRemote(5)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: nil)
            
            firstly({
                return try self.dataSyncer.processDeletionRequests()
            }).then({
                try self.assertDataPointsInRemote(0)
                self.accountUtils?.deleteUser()
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequestWithStartTime() {
        do{
            let response = self.expectationWithDescription("wait for promises")
            
            try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5)
            try populateRemoteDatabase()
            try assertDataPointsInRemote(10)

            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            
            firstly({
                return try self.dataSyncer.processDeletionRequests()
            }).then({
                try self.assertDataPointsInRemote(5)
                self.accountUtils?.deleteUser()
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testProcessDeletionRequestWithEndTime() {
        do{
            let response = self.expectationWithDescription("wait for promises")
            
            try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5)
            try populateRemoteDatabase()
            try assertDataPointsInRemote(10)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            
            firstly({
                return try self.dataSyncer.processDeletionRequests()
            }).then({
                try self.assertDataPointsInRemote(5)
                self.accountUtils?.deleteUser()
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDownloadSensorsFromRemote() {
        do {
            let response = self.expectationWithDescription("wait for promises")
            
            try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5)
            
            firstly({
                return try self.dataSyncer.downloadSensorsFromRemote()
            }).then({
                let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
                XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
                
                print("Test completed.")
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testDownloadSensorsDataFromRemote() {
        do {
            let response = self.expectationWithDescription("wait for promises")
            
            try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5)
            
            firstly ({
                return try dataSyncer.downloadSensorsFromRemote()
            }).then({
                let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
                XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            firstly ({
                try dataSyncer.downloadSensorsDataFromRemote()
            }).then({
                let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
                for sensor in sensorsInLocal{
                    let queryOptions = QueryOptions()
                    let dataPoints = try DatabaseHandler.getDataPoints(sensor.id , queryOptions)
                    XCTAssertEqual(dataPoints.count, 5)
                }
                
                print("Task completed")
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
        
    }
    
    func testUploadSensorsDataToRemote() {
        do{
            let response = self.expectationWithDescription("wait for promises")
            
            try self.dataSyncer.downloadSensorProfiles()
            
            try populateLocalDatabase()
            try assertDataPointsInLocal(5)
            
            firstly ({
                return try dataSyncer.uploadSensorDataToRemote()
            }).then ({
                try self.assertDataPointsInRemote(5)
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testCleanUpLocalStorage() {
        do{
            var response = self.expectationWithDescription("wait for promises")
            
            try self.dataSyncer.downloadSensorProfiles()
            
            // Sensors to be tested
            //1. sensor with uploadEnabled = true and persistLocally = true
            //2. sensor with uploadEnabled = true and persistLocally = false
            //3. sensor with uploadEnabled = false and persistLocally = true
            try createSensorsInLocalDataBase()
            
            // ============
            //1. sensor with uploadEnabled = true and persistLocally = true
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> remain
            //  c. data expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1)
            try self.dataSyncer.uploadSensorDataToRemote()
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            
            firstly({
                try self.dataSyncer.cleanUpLocalStorage()
            }).then({
                //verify the result
                var queryOptions = QueryOptions()
                queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
                try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
                
                queryOptions = QueryOptions()
                queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
                try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
                
                queryOptions = QueryOptions()
                queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
                try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            
            response = self.expectationWithDescription("wait for promises")
            
            // ============
            //2. sensor with uploadEnabled = true and persistLocally = false
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> removed
            //  c. data expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2)
            try self.dataSyncer.uploadSensorDataToRemote()
            
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            
            firstly({
                try self.dataSyncer.cleanUpLocalStorage()
            }).then({
                //verify the result
                var queryOptions = QueryOptions()
                queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
                try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
                
                queryOptions = QueryOptions()
                queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
                try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
                
                queryOptions = QueryOptions()
                queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
                try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            response = self.expectationWithDescription("wait for promises")
            
            // ============
            //3. sensor with uploadEnabled = false and persistLocally = true
            //  a. data expired -> removed
            //  b. data not expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3)

            firstly({
                try self.dataSyncer.cleanUpLocalStorage()
            }).then({
                //verify the result
                var queryOptions = QueryOptions()
                queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
                try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName3, sensorName: self.sensorName3, queryOptions: queryOptions)
                
                queryOptions = QueryOptions()
                queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
                try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName3, sensorName: self.sensorName3, queryOptions: queryOptions)
                response.fulfill()
            }).error({ error in
                XCTFail("Exception was captured. Abort the test.")
            })
            
            self.waitForExpectationsWithTimeout(20.0) { error in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    // MARK: helper functions
    
    func registerAndLogin(){
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
    }
    
    func assertDataPointsInRemote(expectedNumber: Int) throws{
        let dataPoints1 = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
        let dataPoints2 = try SensorDataProxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
        XCTAssertEqual(dataPoints1["data"].arrayObject!.count, expectedNumber)
        XCTAssertEqual(dataPoints2["data"].arrayObject!.count, expectedNumber)
    }
    
    func assertDataPointsInLocal(expectedNumber: Int) throws {
        let sensors = DatabaseHandler.getSensors(sourceName1)
        for sensor in sensors{
            let queryOptions = QueryOptions()
            let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, expectedNumber)
        }
    }
    
    func assertDataPointsForSensorInLocal(expectedNumber: Int, sourceName: String, sensorName: String, queryOptions:QueryOptions? = QueryOptions()) throws {
        let sensor = try DatabaseHandler.getSensor(sourceName, sensorName)
        let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions!)
        XCTAssertEqual(dataPoints.count, expectedNumber)
    }
    
    
    func populateRemoteDatabase(startTime startTime: NSDate? = nil) throws {
        let data1 = getDummyAccelerometerData(time: startTime)
        try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)

        let data2 = getDummyTimeActiveData(time: startTime)
        try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
    }
    
    func populateLocalDatabase(startTime startTime: NSDate? = nil) throws {
        try createSensorsInLocalDataBase()
        try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: startTime)
        try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: startTime)
        try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: startTime)
    }
    
    
    func createSensorsInLocalDataBase() throws {
        var sensorConfig = SensorConfig()
        let sensor1 = Sensor(name: sensorName1, source: sourceName1, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
        try DatabaseHandler.insertSensor(sensor1)
        
        sensorConfig = SensorConfig()
        sensorConfig.persist = false
        let sensor2 = Sensor(name: sensorName2, source: sourceName2, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
        try DatabaseHandler.insertSensor(sensor2)
        
        sensorConfig = SensorConfig()
        sensorConfig.uploadEnabled = false
        let sensor3 = Sensor(name: sensorName3, source: sourceName3, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
        try DatabaseHandler.insertSensor(sensor3)
    }
    
    func insertSensorDataIntoLocalStorage(sourceName: String, sensorName: String, startTime: NSDate? = nil) throws {
        let sensor = try DatabaseHandler.getSensor(sourceName, sensorName)
        var dataArray : Array<AnyObject>
        if sensor.name == sensorName1{
            dataArray = getDummyAccelerometerData(time: startTime)
        } else {
            dataArray = getDummyTimeActiveData(time: startTime)
        }
        for data in dataArray {
            let jsonData = JSON(data)
            let value = JSONUtils.stringify(jsonData["value"])
            let time = NSDate.init(timeIntervalSince1970: (jsonData["time"].doubleValue / 1000) )
            let dataPoint = DataPoint(sensorId: sensor.id, value: value, time: time)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }
    }
    
    // @param time: the datapoints will have time.timeIntervalSince1970 + index
    func getDummyAccelerometerData(var time time: NSDate? = nil) -> Array<AnyObject>{
        if time == nil {
            time = NSDate().dateByAddingTimeInterval(-10)
        }
        let value = ["x-axis": 4, "y-axis": 5, "z-axis": 6]
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Int(time!.timeIntervalSince1970 * 1000) + (i * 1000)), "value": value]
            data.append(dataPoint)
        }
        return data
    }
    
    // @param time: the datapoints will have time.timeIntervalSince1970 + index
    func getDummyTimeActiveData(var time time: NSDate? = nil) -> Array<AnyObject>{
        if time == nil {
            time = NSDate().dateByAddingTimeInterval(-10)
        }
        
        let value = 3
        var data = Array<AnyObject>()
        //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
        for (var i = 0 ; i < 5 ; i++) {
            let dataPoint = ["time": (Int(time!.timeIntervalSince1970 * 1000) + (i * 1000)), "value": value]
            data.append(dataPoint)
        }
        return data
    }

    
    
}

