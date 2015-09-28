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
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(100), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetDataPointWithValidLimit() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 101; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(10), limit: 80, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 80)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetDataPointWithEmptyStartAndEnd() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            // add 50 datapoints with date of 3 years ago
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate().dateByAddingTimeInterval(-3*365*24*60*60), synced: false)
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            // add 50 datapoints with date of recent time
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: nil, endDate: nil, limit: 101, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 100)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    //This is a performance test. should be placed somewhere else
    /*
    func testGetDataPointsPerformanceWith100000() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 100000; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            self.measureBlock(){
                do{
                    try DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(10), limit: 80, sortOrder: SortOrder.Asc)
                } catch{
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
*/
    
    func testInsertDataPointWithInvalidSensorId() {
        do{
            let dataPoint = DataPoint(sensorId: 1, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }catch{
            XCTAssertNotNil(error)
        }
    }

    func testGetDataPointsWithInvalidLimit() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            try DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: -2, sortOrder: SortOrder.Asc)
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }

    func testGetDataPointsWithInvalidSensorId() {

        do{
            let dataPoints = try DatabaseHandler.getDataPoints(sensorId: 1, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 0)
        }catch{
            print(error)
        }
    }

    func testUpdateDataPoint() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(100), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(dataPoints.count, 1)
            XCTAssertEqual(dataPoints[0].getValueInString(), "String value")
            
            dataPoint = dataPoints[0]
            dataPoint.setValue("String value updated")
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            let updatedDataPoints = try! DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate(), limit: 100, sortOrder: SortOrder.Asc)
            XCTAssertEqual(updatedDataPoints.count, 1)
            XCTAssertEqual(updatedDataPoints[0].getValueInString(), "String value updated")
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }


    func testInsertSensorWithValidSetup() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: "user1", source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testInsertSameSensorTwice() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            try DatabaseHandler.insertSensor(sensor)
            
        }catch{
            print((error))
            XCTAssertNotNil(error)
        }
    }
    
    func testInsertSensorWithInvalidUserId() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: "anotheruser", source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testUpdateSensor() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorMeta = "meta data updated"
            sensor.meta = newSensorMeta
            try DatabaseHandler.update(sensor)
            
            let retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.meta, newSensorMeta)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateInvalidUpdateOfSensorName() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorName = "new SensorName"
            sensor.name = newSensorName
            try DatabaseHandler.update(sensor)
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }
    
    func testUpdateSensorWithInvalidUsername() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorName = "sensor1Updated"
            sensor.name = newSensorName
            sensor.userId = "AnotherUser"
            try DatabaseHandler.update(sensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetSensorWithSourceNameAndSensorName() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorWithNonExistingSource() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try DatabaseHandler.getSensor("nonExistingSorce", sensor.name)
            XCTAssertNil(retrievedSensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetSensorWithNonExistingSensorName() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try DatabaseHandler.getSensor(sourceName, "NonExsistingSensorName")
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetSensors() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let retrievedSensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(retrievedSensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorsWithInvalidSorceName() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: sourceName, dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let retrievedSensors = DatabaseHandler.getSensors("NonExistingSourceName")
            XCTAssertEqual(retrievedSensors.count, 0)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorsWithValidSorceNameWithoutSensors() {
        let retrievedSensors = DatabaseHandler.getSensors("NonExistingSourceName")
        XCTAssertEqual(retrievedSensors.count, 0)
    }
    
    func testGetSources() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            //add 2 sensors with source 1 and add 1 sensor with source 2
            var sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource1", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource1", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            //add 1 sensor with another userId and source3
            sensor = Sensor(name: "sensor3", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource2", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            //call getSources
            let sources = DatabaseHandler.getSources()
            XCTAssertEqual(sources.count, 2)
            XCTAssertEqual(sources[0], "testSource1")
            XCTAssertEqual(sources[1], "testSource2")
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }

}
