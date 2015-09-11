//
//  DSESource.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

class DSESource{
    dynamic var id = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var uuid = ""
    dynamic var cs_id = ""
    
    init(id:String, name: String, meta: String, uuid: String, cs_id: String) {
        self.id = id
        self.name = name
        self.meta = meta
        self.uuid = uuid
        self.cs_id = cs_id
        
    }
    
    required convenience init() {
        self.init(id: "", name: "", meta: "", uuid: "", cs_id: "")
    }
}