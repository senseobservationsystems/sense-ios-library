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
        
        // create DSE singleton here
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSetup() {
        let dseRef = DataStorageEngine.sharedInstance // this will be lazy-loaded when first called

    }
}