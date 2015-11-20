//
//  TestDataStorageEngine.swift
//  SensePlatform
//
//  Created by Alex on 11/11/15.
//
//

import XCTest
import RealmSwift
import SwiftyJSON
import PromiseKit
import OHHTTPStubs
@testable import DSESwift

class DataStorageEngineTests: XCTestCase{
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    var config = DSEConfig()
    let sourceName1 = "aim-ios-sdk"
    let sourceName2 = "fitbit"
    let sensorName1 = "accelerometer"
    let sensorName2 = "time_active"
    var sensorConfig = SensorConfig()
    
    override func setUp() {
        super.setUp()
        //Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        let backendStringValue = "STAGING"
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        
        // set the config with CORRECT default values
        self.config.backendEnvironment     = DSEServer.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        self.config.userId = "testuser"
        
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(backendStringValue, forKey: DSEConstants.BACKEND_ENVIRONMENT_KEY)
        
        sensorConfig.uploadEnabled = true
        sensorConfig.persist = true
    }
    
    override func tearDown() {
        print("-------teardown ")
        DataStorageEngine.getInstance().reset()
        OHHTTPStubs.removeAllStubs()
        let realm = try! Realm()
        realm.beginWrite()
        realm.deleteAll()
        try! realm.commitWrite()

        super.tearDown()
    }
    
    func testSetup() {
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
        }catch{
            print(error)
        }
    }
    
    func testStart_receiveSuccessfulCallbacks() {
        // Arrange:
        let expectation = expectationWithDescription("expect callback")
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            
            dse.setInitializationCallback(OnReadyCallback(expectation, expectSuccess: true, isLastCallback: false))
            dse.setSensorsDownloadedCallback(OnSensorsDownloadedCallback(expectation, expectSuccess: true, isLastCallback: false))
            dse.setSensorDataDownloadedCallback(OnSensorDataDownloadedCallback(expectation, expectSuccess: true, isLastCallback: true))
            
            // Act:
            try dse.start()
            
            //Assert: Assertion is held in the callbacks
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
        }catch{
            print(error)
        }
    }
    
    func testStart_whenNoConnection_receiveFailureCallbacks() {
        
        //Arrange:
        let expectation = expectationWithDescription("expect callback")
        
        stub(isHost("sensor-api.staging.sense-os.nl")) { _ in
            let notConnectedError = NSError(domain:NSURLErrorDomain, code:Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue), userInfo:nil)
            return OHHTTPStubsResponse(error:notConnectedError)
        }
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            
            dse.setInitializationCallback(OnReadyCallback(expectation, expectSuccess: false, isLastCallback: true))
            
            // Act:
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            
            //Assert: Assertion is held in the callbacks

        }catch{
            print(error)
        }
    }
    
    func testCreateAndGetSensor_returnCorrectSensor(){
        // Arrange:
        let expectation = expectationWithDescription("expect callback")
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            dse.setSensorsDownloadedCallback(OnSensorsDownloadedCallback(expectation, expectSuccess: true, isLastCallback: true))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            
            // Act:
            let sensor = try dse.createSensor(sourceName1, name: sensorName1)
            let retrievedSensor = try dse.getSensor(sourceName1, sensorName: sensorName1)
            
            // Assert:
            XCTAssertEqual(sensor.name, retrievedSensor!.name)
            XCTAssertEqual(sensor.source, retrievedSensor!.source)
            XCTAssertEqual(JSON(sensor.meta), JSON(retrievedSensor!.meta))
            
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testGetSensors_returnCorrectSensors(){
        // Arrange:
        let expectation = expectationWithDescription("expect callback")
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            dse.setSensorsDownloadedCallback(OnSensorsDownloadedCallback(expectation, expectSuccess: true, isLastCallback: true))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            let sensor1 = try dse.createSensor(sourceName1, name: sensorName1)
            let sensor2 = try dse.createSensor(sourceName1, name: sensorName2)
            let sensor3 = try dse.createSensor(sourceName2, name: sensorName1)
            let sensor4 = try dse.createSensor(sourceName2, name: sensorName2)
            
            // Act: get sensors
            let retrievedSensorsFromSource1 = dse.getSensors(sourceName1)
            let retrievedSensorsFromSource2 = dse.getSensors(sourceName2)
            
            // Assert: check if each parameter of retrieved sensors is the same individuallys
            XCTAssertEqual(sensor1.name, retrievedSensorsFromSource1[0].name)
            XCTAssertEqual(sensor1.source, retrievedSensorsFromSource1[0].source)
            XCTAssertEqual(JSON(sensor1.meta), JSON(retrievedSensorsFromSource1[0].meta))
            
            XCTAssertEqual(sensor2.name, retrievedSensorsFromSource1[1].name)
            XCTAssertEqual(sensor2.source, retrievedSensorsFromSource1[1].source)
            XCTAssertEqual(JSON(sensor2.meta), JSON(retrievedSensorsFromSource1[1].meta))
            
            XCTAssertEqual(sensor3.name, retrievedSensorsFromSource2[0].name)
            XCTAssertEqual(sensor3.source, retrievedSensorsFromSource2[0].source)
            XCTAssertEqual(JSON(sensor3.meta), JSON(retrievedSensorsFromSource2[0].meta))
            
            XCTAssertEqual(sensor4.name, retrievedSensorsFromSource2[1].name)
            XCTAssertEqual(sensor4.source, retrievedSensorsFromSource2[1].source)
            XCTAssertEqual(JSON(sensor4.meta), JSON(retrievedSensorsFromSource2[1].meta))
            
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testGetSources_returnCorrectSources(){
        // Arrange:
        let expectation = expectationWithDescription("expect callback")
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            dse.setSensorsDownloadedCallback(OnSensorsDownloadedCallback(expectation, expectSuccess: true, isLastCallback: true))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            try dse.createSensor(sourceName1, name: sensorName1)
            try dse.createSensor(sourceName1, name: sensorName2)
            try dse.createSensor(sourceName2, name: sensorName1)
            try dse.createSensor(sourceName2, name: sensorName2)
            
            // Act:
            let retrievedSources = dse.getSources()
            
            // Assert:
            XCTAssertEqual(retrievedSources.count, 2)
            XCTAssertEqual(sourceName1, retrievedSources[0])
            XCTAssertEqual(sourceName2, retrievedSources[1])
            
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testGetStatus_beforeAndAfterSetup_awaitingCredentials(){
        do{
            // Arrange:
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            XCTAssertEqual(dse.getStatus(), DSEStatus.AWAITING_CREDENTIALS)
            
            // Act
            try dse.setup(self.config)
            
            // Assert
            XCTAssertEqual(dse.getStatus(), DSEStatus.AWAITING_SENSOR_PROFILES)
        }catch{
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testGetStatus_beforeAndAfterSetup_initialized(){
        do{
            // Arrange: prepare dse and set callback on initialization complete
            let expectation = expectationWithDescription("expect callback")
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            XCTAssertEqual(dse.getStatus(), DSEStatus.AWAITING_CREDENTIALS)
            try dse.setup(self.config)
            dse.setInitializationCallback(OnReadyCallback(expectation, expectSuccess: true, isLastCallback: true, completionHandler:{
                XCTAssertEqual(dse.getStatus(), DSEStatus.INITIALIZED)
            }))
            
            // Act: start dse
            try dse.start()
            
            // Assert: Assert is held in the callback
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
        }catch{
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
  func testSyncData_whenDSEInitialized_remoteHasSensors(){
        // Arrange:
        do{
            let expectation = expectationWithDescription("expect callback")
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)

            let syncSuccuessHandler = {
                print("-----SyncCompleted!!!")
                expectation.fulfill()
            }
            let syncFailureHandler = {(print("SyncFailed"))}
            let syncCompletionCallback = SyncCompletionCallback(successHandler: syncSuccuessHandler, failureHandler: syncFailureHandler)
            dse.setSyncCompletedCallback(syncCompletionCallback)
            try dse.start()
            //print("------", try DatabaseHandler.getSensorProfile(sensorName1))
            

            waitForExpectationsWithTimeout(5) { error in
                print(error)
                print("time out or expectation is fulfilled")
            }

            let valueAccelerometer = ["x-axis": 4, "y-axis": 5, "z-axis": 6]
            let valueTimeActive = 2

            let sensor1 = try dse.createSensor(sourceName1, name: sensorName1, sensorConfig: sensorConfig)
            try sensor1.insertOrUpdateDataPoint(valueAccelerometer, NSDate())
            
            let sensor2 = try dse.createSensor(sourceName1, name: sensorName2, sensorConfig: sensorConfig)
            try sensor2.insertOrUpdateDataPoint(valueTimeActive, NSDate())
            print(try sensor2.getDataPoints(QueryOptions()).count)

            let sensor3 = try dse.createSensor(sourceName2, name: sensorName1, sensorConfig: sensorConfig)
            try sensor3.insertOrUpdateDataPoint(valueAccelerometer, NSDate())
            
            let sensor4 = try dse.createSensor(sourceName2, name: sensorName2, sensorConfig: sensorConfig)
            try sensor4.insertOrUpdateDataPoint(valueTimeActive, NSDate())
            
            let expectation2 = expectationWithDescription("expect callback")
            
            let syncSuccuessHandler2 = {
                do{
                    let retrievedSensors = try SensorDataProxy.getSensors()
                    XCTAssertEqual(retrievedSensors.count, 4)
                    
                    for sensor in retrievedSensors{
                        print(sensor)
                    }
                    
                    XCTAssertEqual(sensor1.name, retrievedSensors[0]["sensor_name"].stringValue)
                    XCTAssertEqual(sensor1.source, retrievedSensors[0]["source_name"].stringValue)
                    XCTAssertEqual(JSON(sensor1.meta), retrievedSensors[0]["meta"])
                    
                    XCTAssertEqual(sensor2.name, retrievedSensors[2]["sensor_name"].stringValue)
                    XCTAssertEqual(sensor2.source, retrievedSensors[2]["source_name"].stringValue)
                    XCTAssertEqual(JSON(sensor2.meta), retrievedSensors[2]["meta"])
                    
                    XCTAssertEqual(sensor3.name, retrievedSensors[1]["sensor_name"].stringValue)
                    XCTAssertEqual(sensor3.source, retrievedSensors[1]["source_name"].stringValue)
                    XCTAssertEqual(JSON(sensor3.meta), retrievedSensors[1]["meta"])
                    
                    XCTAssertEqual(sensor4.name, retrievedSensors[3]["sensor_name"].stringValue)
                    XCTAssertEqual(sensor4.source, retrievedSensors[3]["source_name"].stringValue)
                    XCTAssertEqual(JSON(sensor4.meta), retrievedSensors[3]["meta"])
                    print("fulfilling here!")
                    expectation2.fulfill()
                }catch{
                    print(error)
                    XCTFail("An exception was captured. Abort the test.")
                }
            }
            let syncCompletionCallback2 = SyncCompletionCallback(successHandler: syncSuccuessHandler2, failureHandler: syncFailureHandler)
            
            dse.setSyncCompletedCallback(syncCompletionCallback2)
            
            // Act:
            try dse.syncData()
            
            // Assert: Assert is held in the callback
            
            waitForExpectationsWithTimeout(5) { error in
                print("expectation 2 is fulfilled")
            }
            
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    

}


// MARK: Callbacks


class SyncCompletionCallback: DSEAsyncCallback{
    
    let successHandler: () -> Void
    let failureHandler: () -> Void
    
    init(successHandler: () -> Void, failureHandler: () -> Void){
        self.successHandler = successHandler
        self.failureHandler = failureHandler
    }
    
    func onSuccess() {
        self.successHandler()
    }
    
    func onFailure(error: ErrorType)  {
        self.failureHandler()
    }
}

class OnReadyCallback: DSEAsyncCallback{
    // all the parameters are only for testing
    let expectation: XCTestExpectation
    let expectSuccess: Bool
    let isLastCallback: Bool
    let completionHandler:()->Void
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool, completionHandler:()->Void = {}){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
        self.completionHandler = completionHandler
    }
    
    func onSuccess() {
        print("on Success in onReadyCallback")
        XCTAssert(expectSuccess)
        if self.isLastCallback {
            self.expectation.fulfill()
        }
        completionHandler()
    }
    
    func onFailure(error:ErrorType)  {
        print("on Failure in onReadyCallback")
        XCTAssert(!expectSuccess)
        print(error)
        if self.isLastCallback {
            self.expectation.fulfill()
        }
    }
}

class OnSensorsDownloadedCallback: DSEAsyncCallback{
    // all the parameters are only for testing
    let expectation: XCTestExpectation
    let expectSuccess: Bool
    let isLastCallback: Bool
    let completionHandler:()->Void
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool, completionHandler:()->Void = {}){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
        self.completionHandler = completionHandler
    }
    
    func onSuccess() {
        print("on Success in onSensorsDownloadCallback")
        XCTAssert(expectSuccess)
                self.completionHandler()
        if self.isLastCallback {
            self.expectation.fulfill()
        }
    }
    
    func onFailure(error:ErrorType)  {
        print("on Failure in onSensorsDownloadCallback")
        XCTAssert(!expectSuccess)
        print(error)
        if self.isLastCallback {
            self.expectation.fulfill()
        }
    }
}

class OnSensorDataDownloadedCallback: DSEAsyncCallback{
    
    // all the parameters are only for testing
    let expectation: XCTestExpectation
    let expectSuccess: Bool
    let isLastCallback: Bool
    let completionHandler:()->Void
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool, completionHandler:()->Void = {}){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
        self.completionHandler = completionHandler
    }
    
    func onSuccess() {
        print("on Success in onSensorDataDownloadCallback")
        XCTAssert(expectSuccess)
        completionHandler()
        if self.isLastCallback {
            self.expectation.fulfill()
        }
    }
    
    func onFailure(error:ErrorType)  {
        print("on Failure in onSensorDataDownloadCallback")
        XCTAssert(!expectSuccess)
        print(error)
        if self.isLastCallback {
            self.expectation.fulfill()
        }
    }
}