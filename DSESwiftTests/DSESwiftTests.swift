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
        do{
            dbHandler.createSources("unitTestDevice", uuid: "uuiduuid")
            
            try dbHandler.createSensor("test", sourceId: "1", dataType: "Double", sensorOptions: sensorOptions)
            
            var sensors = [DSESensor]()
            sensors = dbHandler.getSensors("1")
            XCTAssertEqual(sensors.count, 1)
            
            try dbHandler.createSensor("test2", sourceId: "1", dataType: "Double", sensorOptions: sensorOptions)
            
            sensors = dbHandler.getSensors("1")
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
}
