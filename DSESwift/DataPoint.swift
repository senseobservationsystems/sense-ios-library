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
    var value: AnyObject
    var date = NSDate()
    var synced = true

    init(sensorId: String, value: AnyObject, date: NSDate, synced: Bool) {
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
        self.init(sensorId: "", value: 0.0, date: now, synced: true)
    }

}