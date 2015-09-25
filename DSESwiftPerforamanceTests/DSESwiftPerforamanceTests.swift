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
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInsertDataPointsPerformanceWith100000() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            
            
            self.measureBlock(){
                do{
                    for (var i=0; i < 1000; i++){
                        dataPoint = DataPoint(sensorId: sensor.id, value: "{'date':1111111111.111, 'value':{x: 3.34 , y: 5.54, z: 8.78}}", date: NSDate(), synced: false)
                        try dbHandler.insertOrUpdateDataPoint(dataPoint)
                    }
                } catch{
                    print(error)
                    XCTFail("Exception was captured. Abort test")
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
        
        
    }
    
    func testGetDataPointsPerformanceWith100000() {
        let dbHandler = DatabaseHandler()
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: "testSource", dataType: "JSON", csId: "", synced: false)
            try dbHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = dbHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 100000; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", date: NSDate(), synced: false)
                try dbHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            self.measureBlock(){
                do{
                    try dbHandler.getDataPoints(sensorId: sensor.id, startDate: NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60), endDate: NSDate().dateByAddingTimeInterval(10), limit: 80, sortOrder: SortOrder.Asc)
                } catch{
                }
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }

}

