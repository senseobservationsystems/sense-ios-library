//
//  RealmSource.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMSource: Object{
    dynamic var id = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var deviceId = ""
    dynamic var userId = ""
    dynamic var csId = ""
    dynamic var synced = false

    override static func primaryKey() -> String? {
        return "id"
    }
}