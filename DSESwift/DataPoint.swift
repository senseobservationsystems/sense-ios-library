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
    private(set) var value : BaseValue?
    private(set) var date = NSDate()
    var existsInCS = false
    var requiresDeletionInCS = false

    init(sensorId: Int, value: BaseValue?, date: NSDate, existsInCS: Bool, requiresDeletionInCS: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.existsInCS = existsInCS
        self.requiresDeletionInCS = requiresDeletionInCS
    }
    
    convenience init(sensorId: Int, value: BaseValue, date: NSDate) {
        self.init(sensorId: sensorId, value: value, date: date, existsInCS:false, requiresDeletionInCS: false)
    }

    convenience init(rlmDataPoint: RLMDataPoint) {
        let date = NSDate(timeIntervalSince1970: rlmDataPoint.date)
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, date: date, existsInCS: rlmDataPoint.existsInCS, requiresDeletionInCS: rlmDataPoint.requiresDeletionInCS)
    }

    required convenience public init() {
        let now = NSDate()
        self.init(sensorId: -1, value: nil, date: now, existsInCS: false, requiresDeletionInCS: false)
    }
    
    func getId() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
    func setValue(value: BaseValue){
        self.value = value //JSONUtils.stringify(value)
    }
    
    func getValueInInt() -> Int {
        let value = self.value as? RLMIntValue
        return value!.value
        //JSONUtils.getIntValue(self.value)
    }
    
    func getValueInDouble() -> Double {
        let value = self.value as? RLMDoubleValue
        return value!.value
        //JSONUtils.getDoubleValue(self.value)
    }
    
    func getValueInBool() -> Bool {
        let value = self.value as? RLMBoolValue
        return value!.value
        //return JSONUtils.getBoolValue(self.value)
    }
    
    func getValueInString() -> String{
        let value = self.value as? RLMStringValue
        return value!.value
        //return JSONUtils.getStringValue(self.value)
    }
    
//    func getValueInDictionary() -> [String: AnyObject]{
//        let value = self.value as! RLMDictionaryValue
//        return value.value
//        //return JSONUtils.getDictionaryValue(self.value)
//    }
}