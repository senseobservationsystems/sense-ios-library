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

class TestDataSyncer: XCTestCase{
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
    let sourceName1 = "aim-ios-sdk"
    let sensorName1 = "accelerometer"
    
    let sourceName2 = "aim-ios-sdk"
    let sensorName2 = "time_active"
    
    let sourceName3 = "fitbit"
    let sensorName3 = "time_active"
    
    override func setUp() {
        super.setUp()
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSetPersistentPeriod() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            let persistentPeriod : Double = 24*60*60
            try dataSyncer.setPersistentPeriod(persistentPeriod)
            XCTAssertEqual(dataSyncer.persistentPeriod, persistentPeriod)
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testSetSyncRate() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            let syncRate : Double = 30*60
            try dataSyncer.setSyncRate(syncRate)
            XCTAssertEqual(dataSyncer.syncRate, syncRate)
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDefaultValuesForSyncRateAndPersistentPeriod() {
        registerAndLogin()
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        let dataSyncer = DataSyncer(proxy: proxy)
        let expectedSyncRate: Double = 30 * 60
        let expectedPersistentPeriod: Double = 30 * 24 * 60 * 60
        XCTAssertEqual(dataSyncer.syncRate, expectedSyncRate)
        XCTAssertEqual(dataSyncer.persistentPeriod, expectedPersistentPeriod)
    }
    
    func testInitialize() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            try dataSyncer.downloadSensorProfiles()
            let profiles = try DatabaseHandler.getSensorProfiles()
            XCTAssertEqual(profiles.count, 16)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequest() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            
            try populateRemoteDatabase(proxy)
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: nil)
            
            try dataSyncer.processDeletionRequests()
            try checkNumberOfDataPointsInRemote(0, proxy: proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testProcessDeletionRequestWithStartTime() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            
            try populateRemoteDatabase(proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            try populateRemoteDatabase(proxy)
            try checkNumberOfDataPointsInRemote(10, proxy: proxy)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-24*60*60), endTime: nil)
            
            try dataSyncer.processDeletionRequests()
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    /*
    func testProcessDeletionRequestWithEndTime() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            
            try populateRemoteDatabase(proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            try populateRemoteDatabase(proxy)
            try checkNumberOfDataPointsInRemote(10, proxy: proxy)
            
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName1, sensorName: sensorName1, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            try DatabaseHandler.createDataDeletionRequest(sourceName: sourceName2, sensorName: sensorName2, startTime: nil, endTime: NSDate().dateByAddingTimeInterval(-24*60*60))
            
            dataSyncer.processDeletionRequests()
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            accountUtils?.deleteUser()
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDownloadSensorsFromRemote() {
        do {
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            
            try populateRemoteDatabase(proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            
            dataSyncer.downloadSensorsFromRemote()
            let sensorsInLocal = DatabaseHandler.getSensors(sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
        } catch {
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testDownloadSensorsDataFromRemote() {
        do {
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            
            try populateRemoteDatabase(proxy, startTime: NSDate().dateByAddingTimeInterval(-365*24*60*60))
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            
            dataSyncer.downloadSensorsFromRemote()
            let sensorsInLocal = DatabaseHandler.getSensors(sourceName1)
            XCTAssertEqual(sensorsInLocal.count, 2) //accelerometer and time_active
            
            dataSyncer.downloadSensorsDataFromRemote()
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
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            try dataSyncer.downloadSensorProfiles()
            
            try populateLocalDatabase()
            try checkNumberOfDataPointsInLocal(5)
            
            dataSyncer.uploadSensorDataToRemote()
            try checkNumberOfDataPointsInRemote(5, proxy: proxy)
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }

    func testCleanUpLocalStorage() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            try dataSyncer.downloadSensorProfiles()
            
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
            dataSyncer.uploadSensorDataToRemote()
            try insertSensorDataIntoLocalStorage(sourceName1, sensorName: sensorName1, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            dataSyncer.cleanUpLocalStorage()
            //verify the result
            var queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(0, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(5, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(5, sourceName: sourceName1, sensorName: sensorName1, queryOptions: queryOptions)
            
            // ============
            //2. sensor with uploadEnabled = true and persistLocally = false
            //  a. data expired and existsInRemote -> removed
            //  b. data existsInRemote -> removed
            //  c. data expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2)
            dataSyncer.uploadSensorDataToRemote()
            try insertSensorDataIntoLocalStorage(sourceName2, sensorName: sensorName2, startTime: NSDate().dateByAddingTimeInterval(-40*24*60*60))
            dataSyncer.cleanUpLocalStorage()
            //verify the result
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(0, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(0, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-35*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(5, sourceName: sourceName2, sensorName: sensorName2, queryOptions: queryOptions)
            
            // ============
            //3. sensor with uploadEnabled = false and persistLocally = true
            //  a. data expired -> removed
            //  b. data not expired -> remain
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3, startTime: NSDate().dateByAddingTimeInterval(-50*24*60*60))
            try insertSensorDataIntoLocalStorage(sourceName3, sensorName: sensorName3)
            dataSyncer.cleanUpLocalStorage()
            //verify the result
            queryOptions = QueryOptions()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(-45*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(0, sourceName: sourceName3, sensorName: sensorName3, queryOptions: queryOptions)
            
            queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval(-1*24*60*60)
            try checkNumberOfDataPointsForSensorInLocal(5, sourceName: sourceName3, sensorName: sensorName3, queryOptions: queryOptions)
            
            
        } catch {
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    */
    
    // MARK: invalid cases
    func testSetPersistentPeriodWithInvalidValue() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            let persistentPeriod : Double = -24*60*60
            try dataSyncer.setPersistentPeriod(persistentPeriod)
        } catch let e as DataSyncer.DataSyncerError {
            assert( e ==  DataSyncer.DataSyncerError.InvalidPersistentPeriod)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    func testSetSyncRateWithInvalidValue() {
        do{
            registerAndLogin()
            let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
            let dataSyncer = DataSyncer(proxy: proxy)
            let syncRate : Double = -30*60
            try dataSyncer.setSyncRate(syncRate)
        } catch let e as DataSyncer.DataSyncerError {
            assert( e ==  DataSyncer.DataSyncerError.InvalidSyncRate)
        } catch {
            XCTFail("Wrong error")
        }
    }
    
    
    // MARK: helper functions
    
    func registerAndLogin(){
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
    }
    
    func checkNumberOfDataPointsInRemote(expectedNumber: Int, proxy: SensorDataProxy) throws{
        let dataPoints1 = try proxy.getSensorData(sourceName: sourceName1, sensorName: sensorName1)
        let dataPoints2 = try proxy.getSensorData(sourceName: sourceName2, sensorName: sensorName2)
        XCTAssertEqual(dataPoints1["data"].arrayObject!.count, expectedNumber)
        XCTAssertEqual(dataPoints2["data"].arrayObject!.count, expectedNumber)
    }
    
    func checkNumberOfDataPointsInLocal(expectedNumber: Int) throws {
        let sensors = DatabaseHandler.getSensors(sourceName1)
        for sensor in sensors{
            let queryOptions = QueryOptions()
            let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, expectedNumber)
        }
    }
    
    func checkNumberOfDataPointsForSensorInLocal(expectedNumber: Int, sourceName: String, sensorName: String, queryOptions:QueryOptions? = QueryOptions()) throws {
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
            let dataDict = data as! Dictionary<String, AnyObject>
            let value = dataDict["value"]
            let time = NSDate.init(timeIntervalSince1970: (dataDict["time"] as! Double / 1000) )
            let dataPoint = DataPoint(sensorId: sensor.id, value: JSONUtils.stringify(value), time: time)
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

