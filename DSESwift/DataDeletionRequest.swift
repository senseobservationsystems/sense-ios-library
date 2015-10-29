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
    dynamic var startTime : NSDate? = nil
    dynamic var endTime : NSDate? = nil
    
    override static func primaryKey() -> String? {
        return "uuid"
    }
    
}