//
//  DataStorageEngineTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 28/09/15.
//
//

import XCTest
import RealmSwift

@testable import DSESwift

class DataStorageEngineTests: XCTestCase {
    
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
    /*
    func testCreateSensor() {
        let sensorOptions = SensorOptions(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
        let dse = DataStorageEngine()
        let sensor = dse.createSensor("test", name: "test", dataType: "test", sensorOptions: sensorOptions)
    }
    */
    
    func testSetIntValue() {
        let dataPoint = DataPoint()
        let valueInt = 1
        dataPoint.setValue(valueInt)
    }
    
    func testSetDouble() {
        let dataPoint = DataPoint()
        let valueFloat = 2.0
        dataPoint.setValue(valueFloat)

    }
    
    func testSetStringValue() {
        let dataPoint = DataPoint()
        let valueString = "value"
        dataPoint.setValue(valueString)

    }
    
    func testSetDictionaryValue() {
        let dataPoint = DataPoint()
        var valueDictionary = Dictionary<String, AnyObject>()
        let valueFloat = 2.34
        let valueBool = true
        let valueString = "valueString"
        valueDictionary["float"] = String(valueFloat)
        valueDictionary["bool"] = String(valueBool)
        valueDictionary["string"] = "\""+valueString+"\""
        valueDictionary["dict"] = ["subdictkey1": "subvalue1", "subdictkey2": "subvalue2"]
        
        dataPoint.setValue(valueDictionary)
    }

}
