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
            
            let successHandler = {
                expectation.fulfill()
            }
            let failureHandler = {
                XCTFail("The failure handler is triggered. Abort the test.")
            }
            
            dse.setInitializationCallback(TestCallback(failureHandler: failureHandler))
            dse.setSensorsDownloadedCallback(TestCallback(failureHandler: failureHandler))
            dse.setSensorDataDownloadedCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            
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
            
            let successHandler = {
                XCTFail("The success handler is triggered. Abort the test.")
            }
            let failureHandler = {
                expectation.fulfill()
            }
            dse.setInitializationCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            
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
            
            let successHandler = {
                expectation.fulfill()
            }
            let failureHandler = {
                XCTFail("The failure handler is triggered. Abort the test.")
            }
            dse.setSensorsDownloadedCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            
            // Act:
            let retrievedSensor = try dse.getSensor(sourceName1, sensorName: sensorName1)
            
            // Assert:
            XCTAssertEqual(sensorName1, retrievedSensor.name)
            XCTAssertEqual(sourceName1, retrievedSensor.source)
            
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
            
            let successHandler = {
                expectation.fulfill()
            }
            let failureHandler = {
                XCTFail("The failure handler is triggered. Abort the test.")
            }
            dse.setSensorsDownloadedCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            let sensor1 = try dse.getSensor(sourceName1, sensorName: sensorName1)
            let sensor2 = try dse.getSensor(sourceName1, sensorName: sensorName2)
            let sensor3 = try dse.getSensor(sourceName2, sensorName: sensorName1)
            let sensor4 = try dse.getSensor(sourceName2, sensorName: sensorName2)
            
            // Act: get sensors
            let retrievedSensorsFromSource1 = try dse.getSensors(sourceName1)
            let retrievedSensorsFromSource2 = try dse.getSensors(sourceName2)
            
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
            // Prepare callbacks
            let successHandler = {
                expectation.fulfill()
            }
            let failureHandler = {
                XCTFail("The failure handler is triggered. Abort the test.")
            }
            dse.setSensorsDownloadedCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print("time out or expectation is fulfilled")
            }
            try dse.getSensor(sourceName1, sensorName: sensorName1)
            try dse.getSensor(sourceName1, sensorName: sensorName2)
            try dse.getSensor(sourceName2, sensorName: sensorName1)
            try dse.getSensor(sourceName2, sensorName: sensorName2)
            
            // Act:
            let retrievedSources = try dse.getSources()
            
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
            let successHandler = {
                expectation.fulfill()
                XCTAssertEqual(dse.getStatus(), DSEStatus.INITIALIZED)
            }
            let failureHandler = {
                XCTFail("The failure handler is triggered. Abort the test.")
            }
            dse.setInitializationCallback(TestCallback(successHandler: successHandler, failureHandler: failureHandler))
            
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

            let succuessHandler = {
                expectation.fulfill()
            }
            let failureHandler = {(print("SyncFailed"))}
            dse.setSensorDataDownloadedCallback(TestCallback(successHandler: succuessHandler, failureHandler: failureHandler))
            try dse.start()
            

            waitForExpectationsWithTimeout(5) { error in
                print(error)
                print("time out or expectation is fulfilled")
            }

            let valueAccelerometer = ["x-axis": 4, "y-axis": 5, "z-axis": 6]
            let valueTimeActive = 2

            let sensor1 = try dse.getSensor(sourceName1, sensorName: sensorName1)
            try sensor1.setSensorConfig(sensorConfig)
            try sensor1.insertOrUpdateDataPoint(value: valueAccelerometer, time: NSDate())
            
            let sensor2 = try dse.getSensor(sourceName1, sensorName: sensorName2)
            try sensor2.setSensorConfig(sensorConfig)
            try sensor2.insertOrUpdateDataPoint(value: valueTimeActive, time: NSDate())
            print(try sensor2.getDataPoints(QueryOptions()).count)

            let sensor3 = try dse.getSensor(sourceName2, sensorName: sensorName1)
            try sensor3.setSensorConfig(sensorConfig)
            try sensor3.insertOrUpdateDataPoint(value: valueAccelerometer, time: NSDate())
            
            let sensor4 = try dse.getSensor(sourceName2, sensorName: sensorName2)
            try sensor4.setSensorConfig(sensorConfig)
            try sensor4.insertOrUpdateDataPoint(value: valueTimeActive, time: NSDate())
            
            let expectation2 = expectationWithDescription("expect callback")
            
            let succuessHandler2 = {
                do{
                    let retrievedSensors = try SensorDataProxy.getSensors()
                    XCTAssertEqual(retrievedSensors.count, 4)
                    
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
                    expectation2.fulfill()
                }catch{
                    print(error)
                    XCTFail("An exception was captured. Abort the test.")
                }
            }
            
            // Act:
            dse.syncData(TestCallback(successHandler: succuessHandler2, failureHandler: failureHandler))
            
            // Assert: Assert is held in the callback
            
            waitForExpectationsWithTimeout(5) { error in
                print("expectation 2 is fulfilled")
            }
            
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testSyncData_whenDSEisNotInitialized_triggerExceptionHandler(){
        // Arrange: initialize dse and stub the connection to simulate a down connection
        do{
            let expectation = expectationWithDescription("expect callback")
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            let succuessHandler = {
                expectation.fulfill()
            }
            let failureHandler = {(print("SyncFailed"))}
            dse.setSensorDataDownloadedCallback(TestCallback(successHandler: succuessHandler, failureHandler: failureHandler))
            try dse.start()
            
            waitForExpectationsWithTimeout(5) { error in
                print(error)
                print("time out or expectation is fulfilled")
            }
            let expectation2 = expectationWithDescription("expect callback")
            stubDownConnection()
            
            // Act: set sync exception and trigger sync to cause the exception handler to be triggered
            dse.setSyncExceptionHandler({error in
                XCTAssert(error as! DSEError == DSEError.UnknownError)
                expectation2.fulfill()
            })
            let succuessHandler2 = {
                XCTFail("SuccessHandler is called where it should not be. Abort the test.")
            }
            let failureHandler2 = {
                print("error")
            }
            dse.syncData(TestCallback(successHandler: succuessHandler2, failureHandler: failureHandler2))
            
            waitForExpectationsWithTimeout(5) { error in
                print("expectation 2 is fulfilled")
            }
        }catch{
            print(error)
            XCTFail("An exception was captured. Abort the test.")
        }
    }
    
    func testSetAndRemoveSyncExceptionHandler(){
        // Arrange: initialize dse and stub the connection to simulate a down connection
        let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
        let uuid = dse.setSyncExceptionHandler({error in
            XCTAssert(error as! DSEError == DSEError.UnknownError)
        })
        
        // Act: remove a handler
        let result1 = dse.removeSyncExceptionHandler(uuid)
        let result2 = dse.removeSyncExceptionHandler(uuid)
        
        // Assert: assert the return value when the handler exists and when it does not.
        XCTAssertTrue(result1, "Returned false. Failed to remove the handler.")
        XCTAssertFalse(result2, "Returned true where it should be false")
    }
}


// MARK: Callbacks for Tests

class TestCallback: NSObject, DSEAsyncCallback{
    
    let successHandler: () -> Void
    let failureHandler: () -> Void
    
    init(successHandler: () -> Void = {}, failureHandler: () -> Void = {}){
        self.successHandler = successHandler
        self.failureHandler = failureHandler
    }
    
    func onSuccess() {
        self.successHandler()
    }
    
    func onFailure(error: DSEError)  {
        self.failureHandler()
    }
}
