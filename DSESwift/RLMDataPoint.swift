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
    dynamic var value = ""
    dynamic var date = 0.0
    dynamic var synced = true
    
}