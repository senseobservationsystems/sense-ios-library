//
//  TestDataStorageEngine.swift
//  SensePlatform
//
//  Created by Alex on 11/11/15.
//
//

import XCTest
import RealmSwift
@testable import DSESwift
import SwiftyJSON
import PromiseKit

class TestDataStorageEngine: XCTestCase{
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    func testSetup() {
        // im logged in?
        let dse = DataStorageEngine.getInstance() // this will be lazy-loaded when first called
        
        //var credentials = "Timmy"
        var config = DSEConfig()
        config.syncInterval = 10000
        
        
        //dse.setup(config)
        dse.start()
    }
}