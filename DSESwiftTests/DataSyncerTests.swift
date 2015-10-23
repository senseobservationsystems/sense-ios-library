//
//  DataSyncerTest.swift
//  SensePlatform
//
//  Created by Fei on 22/10/15.
//
//

import XCTest
@testable import DSESwift

class DataSyncerTests: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInitializeSensorProfile() {
    
    }
    
    func testDeletionInRemote() {
    
    }
    
    func testUploadToRemote() {
    
    }
    
    func testCleanUpLocalStorage() {
    
    }

}

