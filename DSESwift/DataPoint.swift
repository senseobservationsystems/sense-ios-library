//
//  DataPoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/09/15.
//
//

import Foundation

public class DataPoint{
    private(set) var sensorId = -1
    private(set) var value = ""
    private(set) var date = NSDate()
    var existsInCS = false

    init(sensorId: Int, value: String, date: NSDate, existsInCS: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.existsInCS = existsInCS
    }
    
    private convenience init(sensorId: Int, value: String, date: NSDate) {
        self.init(sensorId: sensorId, value: value, date: date, existsInCS:false)
    }

    convenience init(rlmDataPoint: RLMDataPoint) {
        let date = NSDate(timeIntervalSince1970: rlmDataPoint.date)
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, date: date, existsInCS: rlmDataPoint.existsInCS)
    }
    
    convenience init(sensorId: Int) {
        let now = NSDate()
        self.init(sensorId: sensorId, value: "", date: now, existsInCS: false)
    }

    required convenience public init() {
        let now = NSDate()
        self.init(sensorId: -1, value: "", date: now, existsInCS: false)
    }
    
    func getId() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
    func setDate(date: NSDate){
        self.date = date
    }
    
    func setValue(value: String){
        self.value = value
    }
    
    func getValueInInt() -> Int {
        return JSONUtils.getIntValue(self.value)
    }
    
    func getValueInDouble() -> Double {
        return JSONUtils.getDoubleValue(self.value)
    }
    
    func getValueInBool() -> Bool {
        return JSONUtils.getBoolValue(self.value)
    }
    
    func getValueInString() -> String{
        return JSONUtils.getStringValue(self.value)
    }
    
    func getValueInDictionary() -> [String: AnyObject]{
        return JSONUtils.getDictionaryValue(self.value)
    }
}