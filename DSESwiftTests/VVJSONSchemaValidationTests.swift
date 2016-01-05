//
//  VVJSONSchemaValidationTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 18/12/15.
//
//

import XCTest
import Foundation
import VVJSONSchemaValidation

class VVJSONSchemaValidationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testValidationOnTimeActive(){
        do{
            let schema = "{\"sensor_name\": \"time_active\",\"data_structure\": {\"$schema\": \"http://json-schema.org/draft-04/schema#\",\"type\": \"number\",\"description\": \"The time physically active in seconds\"}}"
            let schemaData: NSData = schema.dataUsingEncoding(NSUTF8StringEncoding)!
            let schemaInDictionary = try NSJSONSerialization.JSONObjectWithData(schemaData, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
            let schemaInDict = schemaInDictionary
            //VVJSONSchemaValication library is written in Objective-C and not completely upto date with Framework. In the original Objective-C it allows us to pass nil for baseURI and reference Storage, but not in swift. It seems like automatic generation of framework is doing something wrong. Thus, we need to pass meaningless empty arguments here.
            let schemaStorage = VVJSONSchemaStorage.init()
            let baseUri = NSURL.init(fileURLWithPath: "")
            let validator = try VVJSONSchema.init(dictionary: schemaInDict, baseURI: baseUri, referenceStorage: schemaStorage)
            try validator.validateObject(0.00000000000000)
        }catch{
            print(error)
            XCTFail()
        }
    }
    
}

