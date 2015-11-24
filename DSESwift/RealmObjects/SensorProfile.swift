//
//  RLMSensorProfile.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 27/10/15.
//
//

import Foundation
import RealmSwift

class SensorProfile: Object{
    dynamic var sensorName = ""
    dynamic var dataStructure = ""

    override static func primaryKey() -> String? {
        return "sensorName"
    }
    
}