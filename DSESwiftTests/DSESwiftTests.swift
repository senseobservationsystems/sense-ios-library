//
//  DSESwiftTests.swift
//  DSESwiftTests
//
//  Created by Alex on 9/9/15.
//
//

import XCTest
import RealmSwift

@testable import DSESwift


class DSESwiftTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
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
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let source = dbHandler.createSources("unitTestDevice", uuid: "uuiduuid")
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            
            try dbHandler.createSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors("1")
            XCTAssertEqual(sensors.count, 1)
            
            try dbHandler.createSensor(sensor)
            
            sensors = dbHandler.getSensors("1")
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
}
