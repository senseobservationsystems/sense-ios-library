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
    dynamic var uuid = ""
    dynamic var user_id = ""
    dynamic var cs_id = ""
    dynamic var synced = false

    override static func primaryKey() -> String? {
        return "id"
    }
}