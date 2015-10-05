//
//  RealmUser.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMUser: Object{

    dynamic var id = ""
    dynamic var username = "test"

    override static func primaryKey() -> String? {
        return "username"
    }
}