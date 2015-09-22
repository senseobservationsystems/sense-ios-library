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

    dynamic var synced = true
    dynamic var value = ""
    dynamic var sensor_id = ""
    func setCompoundSensorID(sensorId: String) {
        self.sensor_id = sensorId
        compoundKey = compoundKeyValue()
    }
    dynamic var date = 0.0
    func setCompoundDate(date: Double) {
        self.date = date
        compoundKey = compoundKeyValue()
    }
    dynamic lazy var compoundKey: String = self.compoundKeyValue()
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(self.sensor_id)-\(String(self.date))"
    }
    
}