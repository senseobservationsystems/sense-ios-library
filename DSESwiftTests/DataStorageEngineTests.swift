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
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        let backendStringValue = "STAGING"
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        
        // set the config with CORRECT default values
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        self.config.userId = "testuser"
        
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(backendStringValue, forKey: BACKEND_ENVIRONMENT_KEY)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
            
            dse.onReady(OnReadyCallback(expectation, expectSuccess: true, isLastCallback: false))
            dse.onSensorsDownloaded(OnSensorsDownloadedCallback(expectation, expectSuccess: true, isLastCallback: false))
            dse.onSensorDataDownloaded(OnSensorDataDownloadedCallback(expectation, expectSuccess: true, isLastCallback: true))
            
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
            
            dse.onReady(OnReadyCallback(expectation, expectSuccess: false, isLastCallback: true))
            
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
    
    func testError(){
        let error1 = DatabaseError.EmptyCredentials
        print(detectErrorType(error1))
        let error2 = RLMError.CanNotChangePrimaryKey
        print(detectErrorType(error2))
        
    }
    
    func detectErrorType(error: ErrorType) -> Bool{
        if let dbError = error as? DatabaseError{
            return dbError == DatabaseError.EmptyCredentials
        }else{
            return false
        }
    }
}

class OnReadyCallback: DSEAsyncCallback{
    // all the parameters are only for testing
    let expectation: XCTestExpectation
    let expectSuccess: Bool
    let isLastCallback: Bool
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
    }
    
    func onSuccess() {
        print("on Success in onReadyCallback")
        XCTAssert(expectSuccess)
        if self.isLastCallback {
            self.expectation.fulfill()
        }
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
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
    }
    
    func onSuccess() {
        print("on Success in onSensorsDownloadCallback")
        XCTAssert(expectSuccess)
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
    
    init(_ expectation: XCTestExpectation, expectSuccess: Bool, isLastCallback: Bool){
        self.expectation = expectation
        self.expectSuccess = expectSuccess
        self.isLastCallback = isLastCallback
    }
    
    func onSuccess() {
        print("on Success in onSensorDataDownloadCallback")
        XCTAssert(expectSuccess)
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