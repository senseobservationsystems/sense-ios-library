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
    
    /**
     * Return the id constructed by "<sensorId>-<timestamp>" in string.
     **/
    func getId() -> String {
        return "\(self.sensorId)-\(String(self.time))"
    }
    
    /**
     * Set time of the data point.
     * @param time: NSDate for the timestamp of the datapoint.
     **/
    func setTime(time: NSDate){
        self.time = time
    }
    
    /**
     * Set value of the data point.
     * @param value: value of the datapoint in String.
     **/
    func setValue(value: String) {
        self.value = value
    }
    
    /**
     * Return the timestamp in Int with milliseconds accuracy
     **/
    func getTimeInMillis() -> Int {
        return Int(self.time.timeIntervalSince1970 * 1000)
    }
    
    /**
     * Return the value in Int.
     **/
    func getValueInInt() -> Int {
        return JSONUtils.getIntValue(self.value)
    }
    /**
     * Return the value in Double.
     **/
    func getValueInDouble() -> Double {
        return JSONUtils.getDoubleValue(self.value)
    }
    
    /**
     * Return the value in Bool.
     **/
    func getValueInBool() -> Bool {
        return JSONUtils.getBoolValue(self.value)
    }
    
    /**
     * Return the value in String.
     **/
    func getValueInString() -> String{
        return JSONUtils.getStringValue(self.value)
    }
    
    /**
     * Return the value in Dictionary.
     **/
    func getValueInDictionary() -> [String: AnyObject]{
        return JSONUtils.getDictionaryValue(self.value)
    }
    
    /**
    * set the existsInRemote state.
    * @param state: true if the datapoint exsists in Remote, or vice versa.
    **/
    func setExistsInRemote(state: Bool){
        self.existsInRemote = state
    }
}