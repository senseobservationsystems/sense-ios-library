//
//  DSESensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

class DSESensor{
    dynamic var id = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var cs_upload_enabled = true
    dynamic var cs_download_enabled = true
    dynamic var persist_locally = true
    dynamic var user: RLMUser
    dynamic var source : RLMSource
    dynamic var data_type = ""
    dynamic var cs_id = ""

    init(id:String, name: String, cs_upload_enabled: Bool, cs_download_enabled: Bool, persist_locally: Bool, user: RLMUser, source: RLMSource, data_type: String, cs_id: String) {
        self.id = id
        self.name = name
        self.cs_upload_enabled = cs_upload_enabled
        self.cs_download_enabled = cs_download_enabled
        self.persist_locally = persist_locally
        self.user = user
        self.source = source
        self.data_type = data_type
        self.cs_id = cs_id
    }
    
    init(sensor: RLMSensor) {
        self.id = sensor.id
        self.name = sensor.name
        self.cs_upload_enabled = sensor.cs_upload_enabled
        self.cs_download_enabled = sensor.cs_download_enabled
        self.persist_locally = sensor.persist_locally
        self.user = sensor.user!
        self.source = sensor.source!
        self.data_type = sensor.data_type
        self.cs_id = sensor.cs_id
        
    }

    required convenience init() {
        self.init( id: "", name: "", cs_upload_enabled: true, cs_download_enabled: true, persist_locally: true, user: RLMUser(), source: RLMSource(), data_type: "", cs_id: "")
    }
}
