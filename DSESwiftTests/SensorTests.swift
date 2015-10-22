//
//  SensorTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 22/10/15.
//
//

import XCTest
@testable import DSESwift

class SensorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValidateNumberValue() {
        let schemaString = "{\"$schema\": \"http://json-schema.org/draft-04/schema#\",\"description\": \"The proximity to an object in cm\",\"type\": \"number\",}"
        XCTAssert(JSONUtils.validateValue(3, schema: schemaString))
    }
    
    func testValidateDictionaryValue() {
        let schemaString = "{\"$schema\": \"http://json-schema.org/draft-04/schema#\", \"type\": \"object\", \"properties\": {\"status\": {\"description\": \"The status of the battery, e.g. charging, discharging, full\", \"type\": \"string\"}, \"level\": {\"description\": \"The battery level in percentage\",\"type\": \"number\"}},}"
        XCTAssert(JSONUtils.validateValue(["status":"full", "level": 100], schema: schemaString))
    }

}
