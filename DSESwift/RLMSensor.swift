//
//  RealmSensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMSensor: Object{
    dynamic var id = -1
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var csUploadEnabled = true
    dynamic var csDownloadEnabled = true
    dynamic var persistLocally = true
    dynamic var userId = ""
    dynamic var source = ""
    dynamic var dataType = ""
    dynamic var synced = false

    override static func primaryKey() -> String? {
        return "id"
    }

}