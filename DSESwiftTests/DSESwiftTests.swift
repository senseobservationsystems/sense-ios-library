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
    
    func testInsertDataPoint() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors()
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            
            let dataPoints = try! dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(1000), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testInsertDataPointWithInvalidSensorId() {
        let dbHandler = DatabaseHandler()
        do{
            let dataPoint = DataPoint(sensorId: 1, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
        }catch{
            XCTAssertNotNil(error)
        }
    }

    func testGetDataPointsWithInvalidLimit() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors()
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            
            let dataPoints = try dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: -1, sortOrder: SortOrder.Asc)
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }

    func testGetDataPointsWithInvalidSensorId() {
        let dbHandler = DatabaseHandler()
        do{
            let dataPoints = try dbHandler.getDataPoints(sensorId: 1, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
        }catch{
            XCTAssertNotNil(error)
        }
    }

    func testUpdateDataPoint() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors()
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            let dataPoints = try! dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(1), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 1)
            XCTAssertEqual(dataPoints[0].getValueInString(), "String value")
            
            dataPoint = dataPoints[0]
            dataPoint.setValue("String value updated")
            try dbHandler.insertOrUpdateDataPoint(dataPoint)
            let updatedDataPoints = try! dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(updatedDataPoints.count, 1)
            XCTAssertEqual(updatedDataPoints[0].getValueInString(), "String value updated")
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }


    func testInsertSensorWithValidSetup() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors()
            XCTAssertEqual(sensors.count, 1)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            sensors = dbHandler.getSensors()
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorWithSourceIdAndSensorName() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var retrievedSensor = try! dbHandler.getSensor(sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            retrievedSensor = try! dbHandler.getSensor(sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSensor() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        let dbHandler = DatabaseHandler()
        do{
            
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            let newSensorName = "sensor1Updated"
            sensor.name = newSensorName
            try dbHandler.update(sensor)
            
            let retrievedSensor = try! dbHandler.getSensor(newSensorName)
            XCTAssertEqual(retrievedSensor.name, newSensorName)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
        
    }

}
