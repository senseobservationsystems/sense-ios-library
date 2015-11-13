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

class TestDataSyncer: XCTestCase{
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
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
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
        
        // set the config with CORRECT default values
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        
        self.dataSyncer.setConfig(self.config)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDefaultValuesForSyncRateAndPersistentPeriod() {
        registerAndLogin()
        let expectedSyncRate: Double = 30 * 60
        let expectedPersistentPeriod: Double = 30 * 24 * 60 * 60
        XCTAssertEqual(self.dataSyncer.syncRate, expectedSyncRate)
        XCTAssertEqual(self.dataSyncer.persistentPeriod, expectedPersistentPeriod)
    }
    
    func testInitialize() {
        do{
            registerAndLogin()
            try self.dataSyncer.downloadSensorProfiles()
            let profiles = try DatabaseHandler.getSensorProfiles()
            XCTAssertEqual(profiles.count, 16)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequest() {
        do{
            registerAndLogin()
            
            try populateRemoteDatabase(self.dataSyncer.proxy)
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: nil)
            
            try self.dataSyncer.processDeletionRequests()
            try assertDataPointsInRemote(0, proxy: self.dataSyncer.proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequestWithStartTime() {
        do{
            registerAndLogin()
            
            try populateRemoteDatabase(self.dataSyncer.proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            try populateRemoteDatabase(self.dataSyncer.proxy)
            try assertDataPointsInRemote(10, proxy: self.dataSyncer.proxy)

            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            
            try self.dataSyncer.processDeletionRequests()
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testProcessDeletionRequestWithEndTime() {
        do{
            registerAndLogin()
            
            try populateRemoteDatabase(self.dataSyncer.proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            try populateRemoteDatabase(self.dataSyncer.proxy)
            try assertDataPointsInRemote(10, proxy: self.dataSyncer.proxy)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            
            try self.dataSyncer.processDeletionRequests()
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDownloadSensorsFromRemote() {
        do {
            registerAndLogin()
            try populateRemoteDatabase(self.dataSyncer.proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            
            try populateRemoteDatabase(self.dataSyncer.proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            
            try self.dataSyncer.downloadSensorsFromRemote()
            let sensorsInLocal = DatabaseHandler.getSensors(sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testDownloadSensorsDataFromRemote() {
        do {
            registerAndLogin()
            
            try populateRemoteDatabase(self.dataSyncer.proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            
            try dataSyncer.downloadSensorsFromRemote()
            let sensorsInLocal = DatabaseHandler.getSensors(sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
            
            try dataSyncer.downloadSensorsDataFromRemote()

            for sensor in sensorsInLocal{
                let queryOptions = QueryOptions()
                let dataPoints = try DatabaseHandler.getDataPoints(sensor.id , queryOptions)
                XCTAssertEqual(dataPoints.count, 5)
            }
            
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
        
    }
    
    func testUploadSensorsDataToRemote() {
        do{
            registerAndLogin()
            try self.dataSyncer.downloadSensorProfiles()
            
            try populateLocalDatabase()
            try assertDataPointsInLocal(5)
            
            try dataSyncer.uploadSensorDataToRemote()
            try assertDataPointsInRemote(5, proxy: self.dataSyncer.proxy)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testCleanUpLocalStorage() {
        do{
            registerAndLogin()
          
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
            try self.dataSyncer.cleanUpLocalStorage()
            //verify the result
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try assertDataPointsForSensorInLocal(0, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try assertDataPointsForSensorInLocal(5, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try assertDataPointsForSensorInLocal(5, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            // ============
            //2. sensor with uploadEnabled = true and persistLocally = false
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> removed
            //  c. data expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2)
            try self.dataSyncer.uploadSensorDataToRemote()
            
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            try self.dataSyncer.cleanUpLocalStorage()
            //verify the result
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try assertDataPointsForSensorInLocal(0, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try assertDataPointsForSensorInLocal(0, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try assertDataPointsForSensorInLocal(5, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            // ============
            //3. sensor with uploadEnabled = false and persistLocally = true
            //  a. data expired -> removed
            //  b. data not expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3)

            try self.dataSyncer.cleanUpLocalStorage()
            //verify the result
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try assertDataPointsForSensorInLocal(0, sourceName: sourceName3, sensorName: sensorName3, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try assertDataPointsForSensorInLocal(5, sourceName: sourceName3, sensorName: sensorName3, queryOptions: queryOptions)
            
            
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
    
    func assertDataPointsInRemote(expectedNumber: Int, proxy: SensorDataProxy) throws{
        let dataPoints1 = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
        let dataPoints2 = try proxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
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
    
    
    func populateRemoteDatabase(proxy: SensorDataProxy, startTime: NSDate? = nil) throws {
        let data1 = getDummyAccelerometerData(time: startTime)
        try proxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)

        let data2 = getDummyTimeActiveData(time: startTime)
        try proxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
        
        NSThread.sleepForTimeInterval(6)
    }
    
    func populateLocalDatabase(startTime: NSDate? = nil) throws {
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
    func getDummyAccelerometerData(var time time: NSDate? = NSDate()) -> Array<AnyObject>{
        if time == nil {
            time = NSDate()
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
    func getDummyTimeActiveData(var time time: NSDate? = NSDate()) -> Array<AnyObject>{
        if time == nil {
            time = NSDate()
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

