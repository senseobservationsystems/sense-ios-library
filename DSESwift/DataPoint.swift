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
    private(set) var time = NSDate()
    var existsInRemote = false

    init(sensorId: Int, value: String, time: NSDate, existsInRemote: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.time = time
        self.existsInRemote = existsInRemote
    }
    
    convenience init(sensorId: Int, value: String, time: NSDate) {
        self.init(sensorId: sensorId, value: value, time: time, existsInRemote:false)
    }

    convenience init(rlmDataPoint: RLMDataPoint) {
        let time = NSDate(timeIntervalSince1970: rlmDataPoint.time)
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, time: time, existsInRemote: rlmDataPoint.existsInRemote)
    }
    
    convenience init(sensorId: Int) {
        let now = NSDate()
        self.init(sensorId: sensorId, value: "", time: now, existsInRemote: false)
    }

    required convenience public init() {
        let now = NSDate()
        self.init(sensorId: -1, value: "", time: now, existsInRemote: false)
    }
    
    func getId() -> String {
        return "\(self.sensorId)-\(String(self.time))"
    }
    
    func setTime(time: NSDate){
        self.time = time
    }
    
    func setValue(value: String) {
        self.value = value
    }
    
    func getTimeInMillis() -> Int {
        return Int(self.time.timeIntervalSince1970 * 1000)
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