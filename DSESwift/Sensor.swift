//
//  Sensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public class Sensor{
    var id = -1
    var name = ""
    var meta = ""
    var csUploadEnabled = true
    var csDownloadEnabled = true
    var persistLocally = true
    var userId = ""
    var source = ""
    var dataType = ""
    var csId = ""
    var synced = false

    init(id:Int,              name: String,   meta:String,      csUploadEnabled: Bool, csDownloadEnabled: Bool,
        persistLocally: Bool, userId: String, source: String,   dataType: String,      csId: String,
        synced: Bool) {
            
        self.id = id
        self.name = name
        self.meta = meta
        self.csUploadEnabled = csUploadEnabled
        self.csDownloadEnabled = csDownloadEnabled
        self.persistLocally = persistLocally
        self.userId = userId
        self.source = source
        self.dataType = dataType
        self.csId = csId
        self.synced = synced
    }
    
    public convenience init(name: String,   sensorOptions: SensorOptions,   userId: String,
                            source: String, dataType: String, csId: String, synced: Bool) {
        self.init(
            id: RLMSensor.getNextKey(),
            name: name,
            meta: sensorOptions.meta,
            csUploadEnabled: sensorOptions.uploadEnabled,
            csDownloadEnabled: sensorOptions.downloadEnabled,
            persistLocally: sensorOptions.persist,
            userId: userId,
            source: source,
            dataType: dataType,
            csId: csId,
            synced: synced
        )
    }
    
    convenience init(_ sensor: RLMSensor) {
        self.init(
            id: sensor.id,
            name: sensor.name,
            meta: sensor.meta,
            csUploadEnabled: sensor.csUploadEnabled,
            csDownloadEnabled: sensor.csDownloadEnabled,
            persistLocally: sensor.persistLocally,
            userId: sensor.userId,
            source: sensor.source,
            dataType: sensor.dataType,
            csId: sensor.csId,
            synced: sensor.synced
        )
    }
    
}
