//
//  RealmDatapoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMDataPoint: Object{
    dynamic var sensorId = ""
    dynamic var value :AnyObject
    dynamic var date = 0.0
    dynamic var synced = true
    
    init(sensorId:String, value: AnyObject, date: Double, synced: Bool) {
        self.sensorId = sensorId
        self.value = value
        self.date = date
        self.synced = synced
        super.init()
    }
    
    required convenience init() {
        self.init(sensorId: "", value: 0.0, date: 0.0, synced: true)
    }
    
}