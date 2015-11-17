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
@testable import DSESwift

class TestDataStorageEngine: XCTestCase{
    
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
            print("error")
        }
    }
    
    func testStart() {
        
        do{
            let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
            try dse.setup(self.config)
            
            dse.onReady(OnReadyCallback())
            
            dse.start()
        }catch{
            print("error")
        }
    }
    
    

}