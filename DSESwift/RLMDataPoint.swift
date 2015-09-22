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
    dynamic var sensorId = ""
    dynamic var date = 0.0
    dynamic lazy var compoundKey: String = self.compoundKeyValue()
    
    func setCompoundSensorID(sensorId: String) {
        self.sensorId = sensorId
        compoundKey = compoundKeyValue()
    }

    func setCompoundDate(date: Double) {
        self.date = date
        compoundKey = compoundKeyValue()
    }

    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func compoundKeyValue() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
}