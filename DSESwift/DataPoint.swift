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
    var value :AnyObject
    var date = 0.0
    var synced = true
    
    init(sensorId:String, value: AnyObject, date: Double, synced: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.synced = synced
    }
    
    convenience init(rlmDataPoint: RLMDataPoint) {
        self.init(sensorId: rlmDataPoint.sensorId, value: rlmDataPoint.value, date: rlmDataPoint.date, synced: rlmDataPoint.synced)
    }
    
    required convenience init() {
        self.init(sensorId: "", value: 0.0, date: 0.0, synced: true)
    }
    
}