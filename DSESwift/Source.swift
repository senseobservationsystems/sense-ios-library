//
//  Source.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public class Source{
    var id = ""
    var name = ""
    var meta = ""
    var deviceId = ""
    var userId = ""
    var csId = ""
    var synced = false
    
    
    init(id: String, name: String, meta: String, deviceId: String, userId:String, csId: String) {
        self.id = id
        self.name = name
        self.meta = meta
        self.deviceId = deviceId
        self.userId = userId
        self.csId = csId
    }
    
    convenience init(name: String, meta: String, deviceId: String, userId: String) {
        self.init(id: NSUUID().UUIDString, name: name, meta: meta, deviceId: deviceId, userId: userId, csId: "")
    }
    
    convenience init(source: RLMSource) {
        self.init(id: source.id, name: source.name, meta: source.meta, deviceId: source.deviceId, userId: source.userId, csId: source.csId)
    }
    
//    public func createSensor(name name: String, dataType: String, options: SensorOptions) throws -> Sensor {
////        var sensor = Sensor(name, options, source.userId
//    }
//    
//    public func getSensor(sensorName: String) -> Sensor {
//        
//    }
//    
//    func getSensors() -> [Sensor] {
//        
//    }
}