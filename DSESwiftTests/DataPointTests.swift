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

class DataPointTests: XCTestCase {
    
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

    
    func testSetIntValue() {
        let dataPoint = DataPoint()
        let valueInt = 1
        dataPoint.setValueWithString(JSONUtils.stringify(valueInt))
        XCTAssertEqual(dataPoint.value, "1")
        XCTAssertEqual(dataPoint.getValueInInt(), valueInt)
    }
    
    func testSetDouble() {
        let dataPoint = DataPoint()
        let valueFloat = 2.01234
        dataPoint.setValueWithString(JSONUtils.stringify(valueFloat))
        XCTAssertEqual(dataPoint.value, "2.01234")
        XCTAssertEqual(dataPoint.getValueInDouble(), valueFloat)
    }
    
    func testSetDoubleWithoutPrecision() {
        let dataPoint = DataPoint()
        let valueFloat = 2.0
        dataPoint.setValueWithString(JSONUtils.stringify(valueFloat))
        XCTAssertEqual(dataPoint.getValueInDouble(), valueFloat)
    }
    
    func testSetStringValue() {
        let dataPoint = DataPoint()
        let valueString = "valueString"
        dataPoint.setValueWithString(JSONUtils.stringify(valueString))
        XCTAssertEqual(dataPoint.value, "valueString")
        XCTAssertEqual(dataPoint.getValueInString(), valueString)

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
        
        dataPoint.setValueWithString(JSONUtils.stringify(valueDictionary))
        let retrievedDictionary = dataPoint.getValueInDictionary()
        XCTAssertEqual(valueDictionary["float"]?.floatValue, retrievedDictionary["float"]?.floatValue)
        XCTAssertEqual(valueDictionary["bool"]?.boolValue, retrievedDictionary["bool"]?.boolValue)
        XCTAssertEqual(valueDictionary["float"]?.boolValue, retrievedDictionary["float"]?.boolValue)
        XCTAssertEqual(valueDictionary["dict"]?.description, retrievedDictionary["dict"]?.description)
    }

}
