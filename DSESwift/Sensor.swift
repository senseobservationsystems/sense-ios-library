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
    var synced = false

    init(id:Int,              name: String,   meta:String,      csUploadEnabled: Bool, csDownloadEnabled: Bool,
        persistLocally: Bool, userId: String, source: String,   dataType: String,  
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
        self.synced = synced
    }
    
    public convenience init(name: String,   sensorOptions: SensorOptions,   userId: String,
                            source: String, dataType: String, synced: Bool) {
        self.init(
            id: DatabaseHandler.getNextKeyForSensor(),
            name: name,
            meta: sensorOptions.meta,
            csUploadEnabled: sensorOptions.uploadEnabled,
            csDownloadEnabled: sensorOptions.downloadEnabled,
            persistLocally: sensorOptions.persist,
            userId: userId,
            source: source,
            dataType: dataType,
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
            synced: sensor.synced
        )
    }
    /*
    public func insertDataPoint(value: AnyObject, _date: NSDate) -> Bool {
    
        //Conversion from value to string
        
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: , date: date, synced: false)
    }
    */
    
    func getDataPoints(startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: SortOrder) -> [DataPoint]{
        var dataPoints = [DataPoint]()
        do{
            dataPoints = try DatabaseHandler.getDataPoints(sensorId: self.id, startDate: startDate, endDate: endDate, limit: limit, sortOrder: sortOrder)
        } catch RLMError.InvalidLimit {
            NSLog("Invalid limit was given.")
        } catch {
            NSLog("Unkown error")
        }
        return dataPoints
    }
    
    func setSensorOptions(sensorOptions: SensorOptions) {
        do{
            let sensor = try DatabaseHandler.getSensor(self.source, self.name)
            sensor.csDownloadEnabled = sensorOptions.downloadEnabled
            sensor.csUploadEnabled = sensorOptions.uploadEnabled
            sensor.meta = sensorOptions.meta
            sensor.persistLocally = sensorOptions.persist
            try DatabaseHandler.update(sensor)
        } catch RLMError.ObjectNotFound {
            NSLog("Sensor does not exist in DB")
        } catch RLMError.DuplicatedObjects{
            NSLog("Sensor is duplicated in DB")
        } catch RLMError.UnauthenticatedAccess {
            NSLog("Sensor does not belong to the current user")
        } catch {
            NSLog("Unknown error")
        }
    }
    
}
