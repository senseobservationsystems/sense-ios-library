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
import OHHTTPStubs

class DataSyncerTests: XCTestCase{
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils
    
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
        registerAndLogin(accountUtils)
        
        
        // set the config with CORRECT default values
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils.sessionId)!
        
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
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testDefaultValuesForSyncRateAndPersistentPeriod() {
        
        let expectedSyncRate: Double = 30 * 60
        let expectedPersistentPeriod: Double = 30 * 24 * 60 * 60
        XCTAssertEqual(self.dataSyncer.syncRate, expectedSyncRate)
        XCTAssertEqual(self.dataSyncer.persistentPeriod, expectedPersistentPeriod)
    }
    
    func testInitialize() {
        do{
            // Act:
            try self.dataSyncer.downloadSensorProfiles()
            
            // Assert:
            let profiles = try DatabaseHandler.getSensorProfiles()
            XCTAssertEqual(profiles.count, 16)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequestWithStartTime() {
        do{
            // Arrange:
            let data1 = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data1)
            let data2 = try populateRemoteDatabase()
            let concatData = concatenateDataArray(array1: data1, array2: data2)
            try assertDataPointsInRemote(10, data: concatData)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            
            // Act:
            try self.dataSyncer.processDeletionRequests()
            
            // Assert:
            try self.assertDataPointsInRemote(5, data: data1)
            self.accountUtils.deleteUser()
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testProcessDeletionRequestWithEndTime() {
        do{
            // Arrange:
            let data1 = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data1)
            let data2 = try populateRemoteDatabase()
            let concatData = concatenateDataArray(array1: data1, array2: data2)
            try assertDataPointsInRemote(10, data: concatData)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            
            // Act:
            try self.dataSyncer.processDeletionRequests()
            
            // Assert:
            try self.assertDataPointsInRemote(5, data:data2)
            self.accountUtils.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDownloadSensorsFromRemote() {
        do {
            // Arrange:
            let data = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data)
            
            // Act:
            try self.dataSyncer.downloadSensorsFromRemote()
            
            // Assert:
            let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testDownloadSensorsDataFromRemote() {
        do {
            // Arrange:
            let data = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data)
            try self.dataSyncer.downloadSensorProfiles()
            try self.dataSyncer.downloadSensorsFromRemote()
            let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
            
            // Act:
            try self.dataSyncer.downloadSensorsDataFromRemote()
            
            // Assert:
            try self.assertDataPointsInLocal(5, data: data)

        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUploadSensorsDataToRemote() {
        do{
            // Arrange:
            try self.dataSyncer.downloadSensorProfiles()
            let data = try populateLocalDatabase()
            try assertDataPointsInLocal(5, data: data)
            
            // Act:
            try dataSyncer.uploadSensorDataToRemote()
            
            // Assert:
            try self.assertDataPointsInRemote(5, data: data)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    // ==== Sensors to be tested for cleanLocalStorage()
    //1. sensor with uploadEnabled = true and persistLocally = true
    //2. sensor with uploadEnabled = true and persistLocally = false
    //3. sensor with uploadEnabled = false and persistLocally = true
    // ===============
    
    //1. sensor with uploadEnabled = true and persistLocally = true
    //  a. data expired and existsInRemote -> removed
    //  b. data existsInRemote -> remain
    //  c. data expired -> remain
    func testCleanLocalStorageForSensorsUploadedAndPersisted() {
        do{
            // Arrange: prepare the various datapoints
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> remain
            //  c. data expired -> remain
            try self.dataSyncer.downloadSensorProfiles()
            try createSensorsInLocalDataBase()
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1)
            try self.dataSyncer.uploadSensorDataToRemote()
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            
            // Act: clean the local database
            try self.dataSyncer.cleanLocalStorage()
            
            // Assert: The number of datapoints per conditions.
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> remain
            //  c. data expired -> remain
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName1, sensorName: self.sensorName1, queryOptions: queryOptions)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    //2. sensor with uploadEnabled = true and persistLocally = false
    //  a. data expired and existsInRemote -> removed
    //  b. data existsInRemote -> removed
    //  c. data expired -> remain
    func testCleanUpLocalStorageForSensorsUploadedNotPersisted() {
        do{
            // Arrange:
            try self.dataSyncer.downloadSensorProfiles()
            try createSensorsInLocalDataBase()
            
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2)
            try self.dataSyncer.uploadSensorDataToRemote()
            
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            
            // Act:
            try self.dataSyncer.cleanLocalStorage()
            
            // Assert: verify the result
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName2, sensorName: self.sensorName2, queryOptions: queryOptions)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    //3. sensor with uploadEnabled = false and persistLocally = true
    //  a. data expired -> removed
    //  b. data not expired -> remain
    func testCleanUpLocalStorageForSensorsNotUploadedPersisted() {
        do{
            // Arrange:
            try self.dataSyncer.downloadSensorProfiles()
            try createSensorsInLocalDataBase()
            
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3)

            // Act:
            try self.dataSyncer.cleanLocalStorage()
            
            // Assert: verify the result
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try self.assertDataPointsForSensorInLocal(0, sourceName: self.sourceName3, sensorName: self.sensorName3, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try self.assertDataPointsForSensorInLocal(5, sourceName: self.sourceName3, sensorName: self.sensorName3, queryOptions: queryOptions)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    // MARK: Test for down connection
    
    func testInitializeWithNoConnection() {
        do{
            try self.dataSyncer.downloadSensorProfiles()
            let profiles = try DatabaseHandler.getSensorProfiles()
            XCTAssertEqual(profiles.count, 16)
        }catch{
            XCTAssert(error as! SensorDataProxy.ProxyError == SensorDataProxy.ProxyError.UnknownError)
        }
    }
    
    func testProcessDeletionRequestWithNoConnection() {
        do{
            let data = try populateRemoteDatabase()
            try assertDataPointsInRemote(5, data: data)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: nil)
            
            stubDownConnection()
            try self.dataSyncer.processDeletionRequests()

        }catch{
            XCTAssert(error as! SensorDataProxy.ProxyError == SensorDataProxy.ProxyError.UnknownError)
        }
    }
    
    func testDownloadSensorsFromRemoteWithNoConnection() {
        do {
            let data = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data)
            
            stubDownConnection()
            try self.dataSyncer.downloadSensorsFromRemote()

        } catch {
            XCTAssert(error as! SensorDataProxy.ProxyError == SensorDataProxy.ProxyError.UnknownError)
        }
    }
    
    func testDownloadSensorsDataFromRemoteWithNoConnection() {
        do {
            
            let data = try populateRemoteDatabase(startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try assertDataPointsInRemote(5, data: data)
            
            try self.dataSyncer.downloadSensorProfiles()
            try self.dataSyncer.downloadSensorsFromRemote()
            self.stubDownConnection()
            let sensorsInLocal = DatabaseHandler.getSensors(self.sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
            try self.dataSyncer.downloadSensorsDataFromRemote()
            
        } catch {
            XCTAssert(error as! SensorDataProxy.ProxyError == SensorDataProxy.ProxyError.UnknownError)
        }
    }
    
    func testUploadSensorsDataToRemoteWithNoConnction() {
        do{
            try self.dataSyncer.downloadSensorProfiles()
            
            let data = try populateLocalDatabase()
            try assertDataPointsInLocal(5, data: data)
            
            self.stubDownConnection()
            try dataSyncer.uploadSensorDataToRemote()
            
        } catch {
            print(error)
            XCTAssert(error as! SensorDataProxy.ProxyError == SensorDataProxy.ProxyError.UnknownError)
        }
    }

    // MARK: helper functions
    
    func stubDownConnection(){
        stub(isHost("sensor-api.staging.sense-os.nl")) { _ in
            let notConnectedError = NSError(domain:NSURLErrorDomain, code:Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue), userInfo:nil)
            return OHHTTPStubsResponse(error:notConnectedError)
        }
    }
    
    func assertDataPointsInRemote(expectedNumber: Int, data:[JSON]? = nil) throws{
        let dataPoints1 = try SensorDataProxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
        let dataPoints2 = try SensorDataProxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
        XCTAssertEqual(dataPoints1["data"].arrayObject!.count, expectedNumber)
        XCTAssertEqual(dataPoints2["data"].arrayObject!.count, expectedNumber)
        //check the contents of the data
        if data != nil {
            XCTAssertEqual(dataPoints1["data"], data![0])
            XCTAssertEqual(dataPoints2["data"], data![1])
        }
    }
    
    func assertDataPointsInLocal(expectedNumber: Int, data: [JSON]? = nil) throws {
        var index = 0
        let sensors = DatabaseHandler.getSensors(sourceName1)
        for sensor in sensors{
            let queryOptions = QueryOptions()
            let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, expectedNumber)
            
            if data != nil {
                let json = try DataSyncer.getJSONArray(dataPoints, sensorName: sensor.name)
                XCTAssertEqual(json, data![index])
            }
            index++
        }
    }
    
    func assertDataPointsForSensorInLocal(expectedNumber: Int, sourceName: String, sensorName: String, queryOptions:QueryOptions? = QueryOptions()) throws {
        let sensor = try DatabaseHandler.getSensor(sourceName, sensorName)
        let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions!)
        XCTAssertEqual(dataPoints.count, expectedNumber)
    }
    
    
    func populateRemoteDatabase(startTime startTime: NSDate? = nil) throws ->[JSON]{
        let data1 = getDummyAccelerometerData(time: startTime)
        try SensorDataProxy.putSensorData(sourceName: sourceName1, sensorName: sensorName1, data: data1)

        let data2 = getDummyTimeActiveData(time: startTime)
        try SensorDataProxy.putSensorData(sourceName: sourceName2, sensorName: sensorName2, data: data2)
        
        return [data1, data2]
    }
    
    func populateLocalDatabase(startTime startTime: NSDate? = nil) throws -> [JSON]{
        try createSensorsInLocalDataBase()
        let data1 = try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: startTime)
        let data2 = try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: startTime)
        let data3 = try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: startTime)
        return [data1, data2, data3]
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
    
    func insertSensorDataIntoLocalStorage(sourceName: String, sensorName: String, startTime: NSDate? = nil) throws -> JSON{
        let sensor = try DatabaseHandler.getSensor(sourceName, sensorName)
        var dataArray : JSON
        if sensor.name == sensorName1{
            dataArray = getDummyAccelerometerData(time: startTime)
        } else {
            dataArray = getDummyTimeActiveData(time: startTime)
        }
        for (_, data):(String, JSON) in dataArray {
            let jsonData = data
            let value = JSONUtils.stringify(jsonData["value"])
            let time = NSDate.init(timeIntervalSince1970: (jsonData["time"].doubleValue / 1000) )
            let dataPoint = DataPoint(sensorId: sensor.id, value: value, time: time)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }
        return dataArray
    }
    
    func concatenateDataArray(array1 array1:[JSON], array2:[JSON]) -> [JSON]{
        return [JSON(array1[0].arrayObject! + array2[0].arrayObject!), JSON(array1[1].arrayObject! + array2[1].arrayObject!)]
    }
    
}

