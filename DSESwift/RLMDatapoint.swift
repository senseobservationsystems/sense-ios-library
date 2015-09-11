//
//  RealmDatapoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMDatapoint: Object{
    dynamic var sensor : RLMSensor
    dynamic var value :AnyObject
    dynamic var date = 0.0
    dynamic var synced = true
    
    init(sensor:RLMSensor, value: AnyObject, date: Double, synced: Bool) {
        self.sensor = sensor
        self.value = value
        self.date = date
        self.synced = synced
        super.init()
    }
    
    required convenience init() {
        self.init(sensor: RLMSensor(), value: 0.0, date: 0.0, synced: true)
    }
    
}