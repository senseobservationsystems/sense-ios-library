//
//  DSESwiftTests.swift
//  DSESwiftTests
//
//  Created by Alex on 9/9/15.
//
//

import XCTest


@testable import DSESwift


class DSESwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
//        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        XCTAssert(true, "Pass")
    }
    
    func testCreateSensor() {
        let dbHandler = DSEDatabaseHandler()
        let sensorOptions = DSESensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        dbHandler.createSensor("test", sourceId: "1", dataType: "Double", sensorOptions: sensorOptions)
        
        dbHandler.getSensors("1")
    }
}
