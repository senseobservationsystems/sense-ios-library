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
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
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
            let source = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source)
            
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(source.id)
            XCTAssertEqual(sensors.count, 1)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", sourceId: source.id, dataType: "JSON", csId: "", synced: false)
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
            let source = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source)
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(source.id)
            XCTAssertEqual(sensors.count, 1)
            
            let dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            
            let dataPoints = try! dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 1)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorWithSourceIdAndSensorName() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let source = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source)
            
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var retrievedSensor = try! dbHandler.getSensor(source.id, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            retrievedSensor = try! dbHandler.getSensor(source.id, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSources() {

        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            //add 3 sources
            let source1 = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source1)
            
            let source2 = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source2)
            
            let source3 = Source(name: "testSource", meta: "",deviceId: NSUUID().UUIDString, userId: "user2")
            try dbHandler.insertSource(source3)
            
            //add 2 sensors with the current userid and source 1 and source 2
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source1.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source2.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            //add 1 sensor with another userId and source3
            sensor = Sensor(name: "sensor3", sensorOptions: sensorOptions, userId: "user2", sourceId: source3.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            //call getSources
            let sources = dbHandler.getSources()
            
            XCTAssertEqual(sources.count, 2)
            XCTAssertEqual(sources[0].name, source1.name)
            XCTAssertEqual(sources[1].name, source2.name)
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSource() {
        let dbHandler = DatabaseHandler()
        do{
            let uuid = NSUUID().UUIDString
            
            let source = Source(name: "testSource", meta: "",deviceId: uuid, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source)
            
            let newSourceName = "testSourceUpdated"
            source.name = newSourceName
            try dbHandler.update(source)
            
            let retrievedSource = try dbHandler.getSource(newSourceName, uuid)
            XCTAssertEqual(retrievedSource.name, newSourceName )
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSensor() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        let dbHandler = DatabaseHandler()
        do{
            let uuid = NSUUID().UUIDString
            
            let source = Source(name: "testSource", meta: "",deviceId: uuid, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            try dbHandler.insertSource(source)
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, sourceId: source.id, dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            let newSensorName = "sensor1Updated"
            sensor.name = newSensorName
            try dbHandler.update(sensor)
            
            let retrievedSensor = try! dbHandler.getSensor(source.id, newSensorName)
            XCTAssertEqual(retrievedSensor.name, newSensorName)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
        
    }
}
