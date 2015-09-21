//
//  DataPoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/09/15.
//
//

import Foundation

class DataPoint{
    var sensorId = ""
    private(set) var value = ""
    var date = NSDate()
    var synced = false

    init(sensorId: String, value: String, date: NSDate, synced: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.synced = synced
    }

    convenience init(rlmDataPoint: RLMDataPoint) {
        let date = NSDate(timeIntervalSince1970: rlmDataPoint.date)
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, date: date, synced: rlmDataPoint.synced)
    }

    required convenience init() {
        let now = NSDate()
        self.init(sensorId: "", value: "", date: now, synced: false)
    }
    
    func getCompoundKey() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
    func setValue(value: Int) {
        self.value = String(value)
    }
    
    func setValue(value: Double) {
        self.value = String(value)
    }
    
    func setValue(value: Bool){
        self.value = String(Int(value))
    }
    
    func setValue(value: [String: AnyObject]){
        self.value = value.description
    }
    
    func getValue(value: String){
        self.value = value
    }
    
    func getValueInInt() -> Int {
        return Int(self.value)!
    }
    
    func getValueInDouble() -> Double {
        return Double(self.value)!
    }
    
    func getValueInBool() -> Bool {
        return ( Int(self.value)  == 1 )
    }
    
    func getValueInDictionary() -> [String: AnyObject]{
        if let data = self.value.dataUsingEncoding(NSUTF8StringEncoding){
            do{
                if let dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as? [String: AnyObject]{
                    return dictionary
                }
            }catch {
                print("error")
            }
        }
        return [String: AnyObject]()
    }

    func getValueInString() -> String{
        return self.value
    }
}