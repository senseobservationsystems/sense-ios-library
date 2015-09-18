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
    
    func testInsertSensor() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let source = Source(name: "testSource", meta: "", uuid: NSUUID().UUIDString)
            try dbHandler.insertSource(source)
            
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(source.id)
            XCTAssertEqual(sensors.count, 1)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            sensors = dbHandler.getSensors(source.id)
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    
    func testInsertDataPoint() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let source = Source(name: "testSource", meta: "", uuid: NSUUID().UUIDString)
            try dbHandler.insertSource(source)
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(source.id)
            XCTAssertEqual(sensors.count, 1)
            
            let dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertDataPoint(dataPoint)
            
            let dataPoints = try dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 1)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorWithSourceIdAndSensorName() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let source = Source(name: "testSource", meta: "", uuid: NSUUID().UUIDString)
            try dbHandler.insertSource(source)
            
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var retrievedSensor = dbHandler.getSensor(source.id, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            retrievedSensor = dbHandler.getSensor(source.id, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSources() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            var source = Source(name: "testSource", meta: "", uuid: NSUUID().UUIDString)
            try dbHandler.insertSource(source)
            
            source = Source(name: "testSource2", meta: "", uuid: NSUUID().UUIDString)
            try dbHandler.insertSource(source)
            
            var sources = dbHandler.getSources(<#T##sourceName: String##String#>, <#T##uuid: String##String#>)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, data_type: "JSON", cs_id: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            retrievedSensor = dbHandler.getSensor(source.id, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSource() {
        
    }
    
    func testUpdateSensor() {
        
    }
    
    func testUpdateDataPoint() {
        
    }
}
