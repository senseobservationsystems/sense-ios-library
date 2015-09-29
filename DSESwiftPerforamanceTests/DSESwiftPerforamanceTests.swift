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
    
    func testInsertDataPointsPerformanceWith1000() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoints = [DataPoint]()
            var date = NSDate()
            
            for (var i=0; i < 1000; i++){
                let dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{'x': 3.34 , 'y': 5.54, 'z': 8.78}}", date: date, synced: false)
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
            
            let results = try DatabaseHandler.getDataPoints(sensorId: sensor.id, startDate: date.dateByAddingTimeInterval(-10000), endDate: date, limit: nil, sortOrder: SortOrder.Asc)
            XCTAssertEqual(results.count, 1000)
        }catch{
            print(error)
            XCTFail("Exception was captured. Abort the test.")
        }
        
        
    }
    
    func testGetDataPointsPerformanceWith100000() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", synced: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 1000; i++){
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

}

