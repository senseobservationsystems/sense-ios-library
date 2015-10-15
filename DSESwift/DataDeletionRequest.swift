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
    dynamic var startDate: NSDate?  // null by default, if not null, change from default
    dynamic var endDate: NSDate?  // null by default, if not null, change from default
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
}