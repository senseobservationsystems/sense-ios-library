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
    var csUploadEnabled = true
    var csDownloadEnabled = true
    var persistLocally = true
    var userId = ""
    var sourceId = ""
    var dataType = ""
    var csId = ""
    var synced = false

    init(id:String,
        name: String,
        meta:String,
        csUploadEnabled: Bool,
        csDownloadEnabled: Bool,
        persistLocally: Bool,
        userId: String,
        sourceId: String,
        dataType: String,
        csId: String,
        synced: Bool
        ) {
            
        self.id = id
        self.name = name
        self.meta = meta
        self.csUploadEnabled = csUploadEnabled
        self.csDownloadEnabled = csDownloadEnabled
        self.persistLocally = persistLocally
        self.userId = userId
        self.sourceId = sourceId
        self.dataType = dataType
        self.csId = csId
        self.synced = synced
    }
    
    convenience init(name: String,
        sensorOptions: SensorOptions,
        userId: String,
        sourceId: String,
        dataType: String,
        csId: String,
        synced: Bool
        ) {
        
        self.init(
            id: NSUUID().UUIDString,
            name: name,
            meta: sensorOptions.meta,
            csUploadEnabled: sensorOptions.uploadEnabled,
            csDownloadEnabled: sensorOptions.downloadEnabled,
            persistLocally: sensorOptions.persist,
            userId: userId,
            sourceId: sourceId,
            dataType: dataType,
            csId: csId,
            synced: synced
        )
    }
    
    convenience init(sensor: RLMSensor) {
        self.init(id: sensor.id,
            name: sensor.name,
            meta: sensor.meta,
            csUploadEnabled: sensor.csUploadEnabled,
            csDownloadEnabled: sensor.csDownloadEnabled,
            persistLocally: sensor.persistLocally,
            userId: sensor.userId,
            sourceId: sensor.sourceId,
            dataType: sensor.dataType,
            csId: sensor.csId,
            synced: sensor.synced)
    }
    
}
