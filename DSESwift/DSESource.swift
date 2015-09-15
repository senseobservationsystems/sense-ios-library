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
    
    init(source: RLMSource) {
        self.id = source.id
        self.name = source.name
        self.meta = source.meta
        self.uuid = source.uuid
        self.cs_id = source.cs_id
    }
}