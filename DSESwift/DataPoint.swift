//
//  DataPoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/09/15.
//
//

import Foundation

public class DataPoint{
    var sensorId = -1
    private(set) var value = ""
    var date = NSDate()
    var synced = false

    init(sensorId: Int, value: String, date: NSDate, synced: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.synced = synced
    }

    convenience init(rlmDataPoint: RLMDataPoint) {
        let date = NSDate(timeIntervalSince1970: rlmDataPoint.date)
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, date: date, synced: rlmDataPoint.synced)
    }

    required convenience public init() {
        let now = NSDate()
        self.init(sensorId: -1, value: "", date: now, synced: false)
    }
    
    func getId() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
    func setValue(value: Int) {
        self.value = String(format:"%d", value)
    }
    
    func setValue(value: Double) {
        self.value = String(format:"%f", value)
    }
    
    func setValue(value: Bool){
        self.value = String(format:"%b", value)
    }
    
    func setValue(value: Dictionary<String, AnyObject>){
        do{
            let jsonData = try NSJSONSerialization.dataWithJSONObject(value, options: NSJSONWritingOptions.PrettyPrinted)
            let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)! as String
            self.value = jsonString
        }catch{
            print("Error while parsing string into dictionary")
        }
    }
    
    func setValue(value: String){
        self.value = self.quote(value)
    }
    
    func getValueInInt() -> Int {
        return NSString(string: self.value).integerValue
    }
    
    func getValueInDouble() -> Double {
        return NSString(string: self.value).doubleValue
    }
    
    func getValueInBool() -> Bool {
        return NSString(string: self.value).boolValue
    }
    
    func getValueInString() -> String{
        return self.unquote(self.value)
    }
    
    func getValueInDictionary() -> [String: AnyObject]{
        if let data = self.value.dataUsingEncoding(NSUTF8StringEncoding){
            do{
                if let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject]{
                    return dictionary
                }
            }catch {
                print("Error while parsing string into dictionary")
            }
        }
        return [String: AnyObject]()
    }


    
    private func quote(string: String) -> String {
        return String(format: "\"%@\"", string)
    }
    
    private func unquote(string: String) -> String {
        return string.stringByReplacingOccurrencesOfString("\"", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}