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
    dynamic var cs_id = ""
    
    init(id:String, name: String, meta: String, uuid: String, cs_id: String) {
        super.init()
        self.id = id
        self.name = name
        self.meta = meta
        self.uuid = uuid
        self.cs_id = cs_id
        
    }
    
    required convenience init() {
        self.init(id: "", name: "", meta: "", uuid: "", cs_id: "")
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}