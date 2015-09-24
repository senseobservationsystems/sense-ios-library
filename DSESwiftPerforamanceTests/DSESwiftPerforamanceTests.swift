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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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

