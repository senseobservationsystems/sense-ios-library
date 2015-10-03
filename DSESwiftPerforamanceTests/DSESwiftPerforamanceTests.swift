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
    
    func testInsertDataPointsPerformanceWith100000() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 100000; i++){
                let value = RLMStringValue()
                value.value = "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}"
                let dataPoint = DataPoint(sensorId: sensor.id, value: value, date: date)
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
            //›XCTAssertEqual(results.count, 1000)
        }catch{
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
        
        
    }
    
    func testGetDataPointsPerformanceWith100000() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csDataPointsDownloaded:false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 100000; i++){
                let value = RLMStringValue()
                value.value = "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}"
                dataPoint = DataPoint(sensorId: sensor.id, value: value, date: NSDate())
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

