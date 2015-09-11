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
    dynamic var id = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var cs_upload_enabled = true
    dynamic var cs_download_enabled = true
    dynamic var persist_locally = true
    dynamic var user : RLMUser?
    dynamic var source : RLMSource?
    dynamic var data_type = ""
    dynamic var cs_id = ""

    init(id:String, name: String, meta: String, cs_upload_enabled: Bool, cs_download_enabled: Bool, persist_locally: Bool, user: RLMUser, source: RLMSource, data_type: String, cs_id: String) {
        self.id = id
        self.name = name
        self.meta = meta
        self.cs_upload_enabled = cs_upload_enabled
        self.cs_download_enabled = cs_download_enabled
        self.persist_locally = persist_locally
        self.user = user
        self.source = source
        self.data_type = data_type
        self.cs_id = cs_id
        super.init()
        
    }
    
    required convenience init() {
        self.init( id: "", name: "", meta: "",cs_upload_enabled: true, cs_download_enabled: true, persist_locally: true, user: RLMUser(), source: RLMSource(), data_type: "", cs_id: "")
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
}