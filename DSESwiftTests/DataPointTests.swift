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
        let value = RLMIntValue()
        value.value = 1
        dataPoint.setValue(value)
        XCTAssertEqual(dataPoint.getValueInInt(), value.value)
    }
    
    func testSetDouble() {
        let dataPoint = DataPoint()
        let value = RLMDoubleValue()
        value.value = 2.345
        dataPoint.setValue(value)
        XCTAssertEqual(dataPoint.getValueInDouble(), value.value)
    }
    
    func testSetDoubleWithoutPrecision() {
        let dataPoint = DataPoint()
        let value = RLMDoubleValue()
        value.value = 2.0
        dataPoint.setValue(value)
        XCTAssertEqual(dataPoint.getValueInDouble(), value.value)
    }
    
    func testSetStringValue() {
        let dataPoint = DataPoint()
        let value = RLMStringValue()
        value.value = "valueString"
        dataPoint.setValue(value)
        XCTAssertEqual(dataPoint.getValueInString(), value.value)

    }
//    
//    func testSetDictionaryValue() {
//        let dataPoint = DataPoint()
//        let value = RLMDictionaryValue()
//        var valueDictionary = Dictionary<String, AnyObject>()
//        let valueFloat = 2.34
//        let valueBool = true
//        let valueString = "valueString"
//        valueDictionary["float"] = String(valueFloat)
//        valueDictionary["bool"] = String(valueBool)
//        valueDictionary["string"] = "\""+valueString+"\""
//        valueDictionary["dict"] = ["subdictkey1": "subvalue1", "subdictkey2": "subvalue2"]
//        value.value = valueDictionary
//        
//        dataPoint.setValue(value)
//        let retrievedDictionary = dataPoint.getValueInDictionary()
//        XCTAssertEqual(valueDictionary["float"]?.floatValue, retrievedDictionary["float"]?.floatValue)
//        XCTAssertEqual(valueDictionary["bool"]?.boolValue, retrievedDictionary["bool"]?.boolValue)
//        XCTAssertEqual(valueDictionary["float"]?.boolValue, retrievedDictionary["float"]?.boolValue)
//        XCTAssertEqual(valueDictionary["dict"]?.description, retrievedDictionary["dict"]?.description)
//    }

}
