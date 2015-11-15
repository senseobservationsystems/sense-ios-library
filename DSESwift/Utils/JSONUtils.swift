//
//  JSONUtils.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 29/09/15.
//
//

import Foundation
import VVJSONSchemaValidation
import SwiftyJSON

public class JSONUtils{

    public class func stringify(value: AnyObject?)-> String {
        if value == nil {
            return ""
        }else{
            return self.stringify(JSON(value!))
        }
    }
    
    public class func stringify(json:JSON) -> String{
        return json.rawString(options: NSJSONWritingOptions(rawValue: 0))!;
    }
    
    public class func jsonToData(json:JSON) throws -> NSData{
        return try json.rawData();
    }
    
    class func getIntValue(jsonString: String) -> Int {
        return NSString(string: jsonString).integerValue
    }
    
    class func getDoubleValue(jsonString: String) -> Double {
        return NSString(string: jsonString).doubleValue
    }
    
    class func getBoolValue(jsonString: String) -> Bool {
        return NSString(string: jsonString).boolValue
    }
    
    class func getStringValue(jsonString: String) -> String{
        return self.unquote(jsonString)
    }
    
    class func getDictionaryValue(jsonString: String) -> [String: AnyObject]{
        if (jsonString.isEmpty){
            return [String: AnyObject]()
        }
        var result = [String: AnyObject]()
        if let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding){
            do{
                if let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject]{
                    result = dictionary
                }
            }catch {
                print("Error while parsing string into dictionary")
            }
        }
        return result
    }
    
    public class func convertArrayOfDataPointIntoJSONArrayWithIntValue(dataPoints: Array<DataPoint>) -> JSON{
        var dataArray = Array<AnyObject>()
        for dataPoint in dataPoints {
            let dataDict = ["time": dataPoint.getTimeInMillis(), "value": dataPoint.getValueInInt()]
            dataArray.append(dataDict)
        }
        return JSON(dataArray)
    }
    
    public class func convertArrayOfDataPointIntoJSONArrayWithDoubleValue(dataPoints: Array<DataPoint>) -> JSON{
        var dataArray = Array<AnyObject>()
        for dataPoint in dataPoints {
            let dataDict = ["time": dataPoint.getTimeInMillis(), "value": dataPoint.getValueInDouble()]
            dataArray.append(dataDict)
        }
        return JSON(dataArray)
    }
    
    public class func convertArrayOfDataPointIntoJSONArrayWithBoolValue(dataPoints: Array<DataPoint>) -> JSON{
        var dataArray = Array<AnyObject>()
        for dataPoint in dataPoints {
            let dataDict = ["time": dataPoint.getTimeInMillis(), "value": dataPoint.getValueInBool()]
            dataArray.append(dataDict)
        }
        return JSON(dataArray)
    }
    
    public class func convertArrayOfDataPointIntoJSONArrayWithStringValue(dataPoints: Array<DataPoint>) -> JSON{
        var dataArray = Array<AnyObject>()
        for dataPoint in dataPoints {
            let dataDict = ["time": dataPoint.getTimeInMillis(), "value": dataPoint.getValueInString()]
            dataArray.append(dataDict)
        }
        return JSON(dataArray)
    }
    
    public class func convertArrayOfDataPointIntoJSONArrayWithDictionaryValue(dataPoints: Array<DataPoint>) -> JSON{
        var dataArray = Array<AnyObject>()
        for dataPoint in dataPoints {
            let dataDict = ["time": dataPoint.getTimeInMillis(), "value": dataPoint.getValueInDictionary()]
            dataArray.append(dataDict)
        }
        return JSON(dataArray)
    }
    
    public class func validateValue(value: AnyObject, schema: String) -> Bool{
        do{
            let jsonSchamaValidator = try getJSONSchemaValidator(schema)
            try jsonSchamaValidator.validateObject(value)
            return true
            
        }catch{
            return false
        }
    }
    
    private class func getJSONSchemaValidator(schema: String) throws -> VVJSONSchema{
        let schemaInDict = try getSchemaInDictionary(schema)
        //VVJSONSchemaValication library is written in Objective-C and not completely upto date with Framework. In the original Objective-C it allows us to pass nil for baseURI and reference Storage, but not in swift. It seems like automatic generation of framework is doing something wrong. Thus, we need to pass meaning less empty stuff here.
        let schemaStorage = VVJSONSchemaStorage.init()
        let baseUri = NSURL.init(fileURLWithPath: "")
        return try VVJSONSchema.init(dictionary: schemaInDict, baseURI: baseUri, referenceStorage: schemaStorage)
    }
    
    private class func getSchemaInDictionary(schema: String) throws -> Dictionary<String, AnyObject>? {
        let schemaData: NSData = schema.dataUsingEncoding(NSUTF8StringEncoding)!
        return try NSJSONSerialization.JSONObjectWithData(schemaData, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
    }

    private class func isDouble(number: Double) -> Bool {
        return number != floor(number)
    }
    
    private class func quote(string: String) -> String {
        return String(format: "\"%@\"", string)
    }
    
    private class func unquote(string: String) -> String {
        return string.stringByReplacingOccurrencesOfString("\"", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}