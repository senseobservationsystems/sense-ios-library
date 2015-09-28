//
//  Sensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

let kCSDATA_TYPE_STRING = "string"
let kCSDATA_TYPE_JSON = "json"
let kCSDATA_TYPE_INTEGER = "integer"
let kCSDATA_TYPE_FLOAT = "float"
let kCSDATA_TYPE_BOOL = "bool"

public enum SortOrder{
    case Asc
    case Desc
}


/**
* //TODO: Add documentation
*
*/
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
            meta: sensorOptions.meta!,
            csUploadEnabled: sensorOptions.uploadEnabled!,
            csDownloadEnabled: sensorOptions.downloadEnabled!,
            persistLocally: sensorOptions.persist!,
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
    
    public func insertDataPoint(value: String, _ date: NSDate) -> Bool {
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: value, date: date, synced: false)
        do{
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        } catch {
            NSLog("Failed to insert DataPoint")
            return false
        }
    }
    
    public func insertDataPoint(value: NSDictionary, _ date: NSDate) -> Bool {
        do{
            let data = try NSJSONSerialization.dataWithJSONObject(value, options: NSJSONWritingOptions.PrettyPrinted)
            let json = String(data: data, encoding: NSUTF8StringEncoding)
            let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: json!, date: date, synced: false)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        }catch{
            NSLog("Failed to insert DataPoint")
            return false
        }
    }
    
    public func insertDataPoint(value: Int, _ date: NSDate) -> Bool {
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: String(value), date: date, synced: false)
        do{
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        } catch {
            NSLog("Failed to insert DataPoint")
            return false
        }
    }
    
    public func insertDataPoint(value: Float, _ date: NSDate) -> Bool {
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: String(value), date: date, synced: false)
        do{
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        } catch {
            NSLog("Failed to insert DataPoint")
            return false
        }
    }
    
    public func insertDataPoint(value: Bool, _ date: NSDate) -> Bool {
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: String(Int(value)), date: date, synced: false)
        do{
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        } catch {
            NSLog("Failed to insert DataPoint")
            return false
        }
    }
    
    public func getDataPoints(startDate: NSDate?, endDate: NSDate?, limit: Int?, sortOrder: SortOrder) throws -> [DataPoint]{
        var dataPoints = [DataPoint]()
        do{
            dataPoints = try DatabaseHandler.getDataPoints(sensorId: self.id, startDate: startDate, endDate: endDate, limit: limit, sortOrder: sortOrder)
        } catch RLMError.InvalidLimit {
            throw DatabaseError.InvalidLimit
        } catch {
            throw DatabaseError.UnknownError
        }
        return dataPoints
    }
    
    /**
    * Apply options for the sensor.
    * fields in `options` which are `null` will be ignored.
    * @param options
    * @return Returns the applied options.
    */
    public func setSensorOptions(sensorOptions: SensorOptions) throws {
        do{
            let sensor = try DatabaseHandler.getSensor(self.source, self.name)
            let updatedSensor = getSensorWithUpdatedOptions(sensor, sensorOptions)
            try DatabaseHandler.update(updatedSensor)
        } catch RLMError.ObjectNotFound {
            throw DatabaseError.ObjectNotFound
        } catch RLMError.DuplicatedObjects{
            throw DatabaseError.DuplicatedObjects
        } catch RLMError.UnauthenticatedAccess {
            throw DatabaseError.UnauthenticatedAccess
        } catch {
            throw DatabaseError.UnknownError
        }
    }
    
    private func getSensorWithUpdatedOptions(sensor: Sensor, _ sensorOptions: SensorOptions) -> Sensor{
        if (sensorOptions.downloadEnabled != nil){
            sensor.csDownloadEnabled = sensorOptions.downloadEnabled!
        }
        if (sensorOptions.uploadEnabled != nil){
            sensor.csUploadEnabled = sensorOptions.uploadEnabled!
        }
        if (sensorOptions.meta != nil){
            sensor.meta = sensorOptions.meta!
        }
        if (sensorOptions.persist != nil){
            sensor.persistLocally = sensorOptions.persist!
        }
        return sensor
    }
    
    
}
