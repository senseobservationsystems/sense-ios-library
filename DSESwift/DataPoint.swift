//
//  DataPoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/09/15.
//
//

import Foundation

/**
 * The DataPoint class can hold a single data point of for a sensor.
 *
 */
@objc public class DataPoint: NSObject{
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

    required convenience public override init() {
        let now = NSDate()
        self.init(sensorId: -1, value: "", time: now, existsInRemote: false)
    }
    
    /**
     * Return the id constructed by "<sensorId>-<timestamp>" in string.
     **/
    public func getId() -> String {
        return "\(self.sensorId)-\(String(self.time))"
    }
    
    /**
     * Set time of the data point.
     * @param time: NSDate for the timestamp of the datapoint.
     **/
    public func setTimeWithNSDate(time: NSDate){
        self.time = time
    }
    
    /**
     * Set value of the data point.
     * @param value: value of the datapoint in String.
     **/
    public func setValueWithString(value: String) {
        self.value = value
    }
    
    /**
     * Return the timestamp in Int with milliseconds accuracy
     **/
    public func getTimeInMillis() -> Double {
        return round(self.time.timeIntervalSince1970 * 1000)
    }
    
    /**
     * Return the value in Int.
     **/
    public func getValueInInt() -> Int {
        return JSONUtils.getIntValue(self.value)
    }
    /**
     * Return the value in Double.
     **/
    public func getValueInDouble() -> Double {
        return JSONUtils.getDoubleValue(self.value)
    }
    
    /**
     * Return the value in Bool.
     **/
    public func getValueInBool() -> Bool {
        return JSONUtils.getBoolValue(self.value)
    }
    
    /**
     * Return the value in String.
     **/
    public func getValueInString() -> String{
        return JSONUtils.getStringValue(self.value)
    }
    
    /**
     * Return the value in Dictionary.
     **/
    public func getValueInDictionary() -> [String: AnyObject]{
        return JSONUtils.getDictionaryValue(self.value)
    }
    
    /**
    * set the existsInRemote state.
    * @param state: true if the datapoint exsists in Remote, or vice versa.
    **/
    func setExistsInRemoteWithBool(state: Bool){
        self.existsInRemote = state
    }
}