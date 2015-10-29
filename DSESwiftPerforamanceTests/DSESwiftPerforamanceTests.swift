//
//  DSESwiftPerforamanceTests.swift
//  DSESwiftPerforamanceTests
//
//  Created by Tatsuya Kaneko on 24/09/15.
//
//

import XCTest
import RealmSwift

@testable import DSESwift


class DSESwiftPerformanceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        super.tearDown()
    }
 
    func testCreate1000datapoints() {
        let sensorConfig = SensorConfig(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName, nil)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            measureBlock({ 
                for (var i=0; i < 1000; i++){
                    let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date)
                    dataPoints.append(dataPoint)
                    date = date.dateByAddingTimeInterval(1)
                }
            })
            
            
        }catch{
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testInsertDataPointsPerformanceWith1000() {
        let sensorConfig = SensorConfig(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName, nil)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 1000; i++){
                let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date)
                dataPoints.append(dataPoint)
                date = date.dateByAddingTimeInterval(1)
            }
            
            self.measureBlock(){
                do{
                    for dataPoint in dataPoints {
                        try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
                    }
                } catch{
                    print(error)
                    XCTFail("Exception was captured. Abort test")
                }
            }
            
            var queryOptions = QueryOptions()
            queryOptions.startDate = date.dateByAddingTimeInterval(-10000)
            queryOptions.endDate = date
            
            let results = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            //XCTAssertEqual(results.count, 1000)
        }catch{
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetDataPointsPerformanceWith1000() {
        let sensorConfig = SensorConfig(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded:false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName, nil)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 1000; i++){
                let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date)
                dataPoints.append(dataPoint)
                date = date.dateByAddingTimeInterval(1)
            }
            
            for dataPoint in dataPoints {
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            
            var queryOptions = QueryOptions()
            queryOptions.startDate = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endDate = NSDate().dateByAddingTimeInterval(10)
            queryOptions.limit = 80
            
            self.measureBlock(){
                do{
                    try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
                } catch{
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    
    func testInsertDataPointsPerformanceWith100000() {
        let sensorConfig = SensorConfig(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName, nil)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 100000; i++){
                let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date)
                dataPoints.append(dataPoint)
                date = date.dateByAddingTimeInterval(1)
            }
            
            self.measureBlock(){
                do{
                    for dataPoint in dataPoints {
                        try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
                    }
                } catch{
                    print(error)
                    XCTFail("Exception was captured. Abort test")
                }
            }
            
            var queryOptions = QueryOptions()
            queryOptions.startDate = date.dateByAddingTimeInterval(-10000)
            queryOptions.endDate = date
            
            let results = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            //XCTAssertEqual(results.count, 1000)
        }catch{
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
        
        
    }
    
    func testGetDataPointsPerformanceWith100000() {
        let sensorConfig = SensorConfig(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded:false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName, nil)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 100000; i++){
                let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date)
                dataPoints.append(dataPoint)
                date = date.dateByAddingTimeInterval(1)
            }
            
            for dataPoint in dataPoints {
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            var queryOptions = QueryOptions()
            queryOptions.startDate = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endDate = NSDate().dateByAddingTimeInterval(10)
            queryOptions.limit = 80
            
            self.measureBlock(){
                do{
                    try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
                } catch{
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    

}

