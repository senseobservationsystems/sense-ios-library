//
//  Sensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

class Sensor{
    var id = ""
    var name = ""
    var meta = ""
    var cs_upload_enabled = true
    var cs_download_enabled = true
    var persist_locally = true
    var user_id = ""
    var source_id = ""
    var data_type = ""
    var cs_id = ""
    var synced = false

    init(id:String, name: String, meta:String, cs_upload_enabled: Bool, cs_download_enabled: Bool, persist_locally: Bool, userId: String, sourceId: String, data_type: String, cs_id: String, synced: Bool) {
        self.id = id
        self.name = name
        self.meta = meta
        self.cs_upload_enabled = cs_upload_enabled
        self.cs_download_enabled = cs_download_enabled
        self.persist_locally = persist_locally
        self.user_id = userId
        self.source_id = sourceId
        self.data_type = data_type
        self.cs_id = cs_id
        self.synced = synced
    }
    
    convenience init(name: String, sensorOptions: SensorOptions, userId: String, sourceId: String, data_type: String, cs_id: String, synced: Bool) {
        
        self.init(id: NSUUID().UUIDString, name: name, meta: sensorOptions.meta,cs_upload_enabled: sensorOptions.uploadEnabled, cs_download_enabled: sensorOptions.downloadEnabled, persist_locally: sensorOptions.persist, userId: userId, sourceId: sourceId, data_type: data_type, cs_id: cs_id, synced: synced)
    }
    
    convenience init(sensor: RLMSensor) {
        self.init(id: NSUUID().UUIDString, name: sensor.name, meta: sensor.meta, cs_upload_enabled: sensor.cs_upload_enabled, cs_download_enabled: sensor.cs_download_enabled, persist_locally: sensor.persist_locally, userId: sensor.user_id, sourceId: sensor.source_id, data_type: sensor.data_type, cs_id: sensor.cs_id, synced: sensor.synced)
    }
    
}
