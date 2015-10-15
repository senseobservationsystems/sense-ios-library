//
//  RLMDataDeletionRequest.swift
//  SensePlatform
//
//  Created by Fei on 15/10/15.
//
//

import Foundation
import RealmSwift

class DataDeletionRequest: Object {
    dynamic var uuid = ""
    dynamic var userId = ""
    dynamic var sensorName = ""
    dynamic var sourceName = ""
    dynamic var startDate: Double = -1.0  // -1.0 as null by default, if not null, change from default
    dynamic var endDate: Double = -1.0 // -1.0 as null by default, if not null, change from default
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
}