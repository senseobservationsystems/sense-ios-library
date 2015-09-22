//
//  Source.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

class Source{
    var id = ""
    var name = ""
    var meta = ""
    var uuid = ""
    var user_id = ""
    var cs_id = ""
    var synced = false
    
    
    init(id: String, name: String, meta: String, uuid: String, user_id:String, cs_id: String) {
        self.id = id
        self.name = name
        self.meta = meta
        self.uuid = uuid
        self.user_id = user_id
        self.cs_id = cs_id
    }
    
    convenience init(name: String, meta: String, uuid: String, user_id: String) {
        self.init(id: NSUUID().UUIDString, name: name, meta: meta, uuid: uuid, user_id: user_id, cs_id: "")
    }
    
    convenience init(source: RLMSource) {
        self.init(id: source.id, name: source.name, meta: source.meta, uuid: source.uuid, user_id: source.user_id, cs_id: source.cs_id)
    }
}