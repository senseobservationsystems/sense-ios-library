//
//  Source.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

enum SourceError: ErrorType {
    case SensorAlreadyExists
}

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
    
    public func createSensor(name name: String, dataType: String, options: SensorOptions) throws -> Sensor {
        let dbHandler = DatabaseHandler()
        
        // first check if the sensor already exists
        do {
            // if the sensor does not exist, this method will throw an error. We want this to throw an error here.
            let _ = try dbHandler.getSensor(self.id, name)
        }
        catch {
            // if we're here the sensor does not yet exist
            let sensor = Sensor(name: name, sensorOptions: options, userId: self.userId, sourceId: self.id, dataType: dataType, csId: self.csId, synced:false)
            try dbHandler.insertSensor(sensor);
            return sensor;
        }
        
        // if the sensor was returned in the catch, we will not be here.
        throw SourceError.SensorAlreadyExists
    }
    
    public func getSensor(sensorName: String) throws -> Sensor {
        let dbHandler = DatabaseHandler()
        return try dbHandler.getSensor(self.id, name)
    }

    public func getSensors() -> [Sensor] {
        let dbHandler = DatabaseHandler()
        return dbHandler.getSensors(self.id);
    }
}