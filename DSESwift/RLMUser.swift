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
    dynamic var username = ""
    
    init(id:String, username: String) {
        self.id = id
        self.username = username
        super.init()
    }
    
    required convenience init() {
        self.init(id: "",username: "")
    }
    
    override static func primaryKey() -> String? {
        return "username"
    }
}