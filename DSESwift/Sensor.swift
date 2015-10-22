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
    var meta: Dictionary<String, AnyObject>?
    var csUploadEnabled = true
    var csDownloadEnabled = true
    var persistLocally = true
    var userId = ""
    var source = ""
    var dataType = ""
    var csDataPointsDownloaded = false

    init(id:Int,              name: String,   meta:Dictionary<String, AnyObject>?, csUploadEnabled: Bool, csDownloadEnabled: Bool,
        persistLocally: Bool, userId: String, source: String, dataType: String, csDataPointsDownloaded: Bool) {
            
        self.id = id
        self.name = name
        self.meta = meta
        self.csUploadEnabled = csUploadEnabled
        self.csDownloadEnabled = csDownloadEnabled
        self.persistLocally = persistLocally
        self.userId = userId
        self.source = source
        self.dataType = dataType
        self.csDataPointsDownloaded = csDataPointsDownloaded
    }
    
    public convenience init(name: String,   sensorOptions: SensorOptions,   userId: String,
                            source: String, dataType: String, csDataPointsDownloaded: Bool) {
        self.init(
            id: DatabaseHandler.getNextKeyForSensor(),
            name: name,
            meta: sensorOptions.meta,
            csUploadEnabled: sensorOptions.uploadEnabled!,
            csDownloadEnabled: sensorOptions.downloadEnabled!,
            persistLocally: sensorOptions.persist!,
            userId: userId,
            source: source,
            dataType: dataType,
            csDataPointsDownloaded: csDataPointsDownloaded
        )
    }
    
    convenience init(_ sensor: RLMSensor) {
        self.init(
            id: sensor.id,
            name: sensor.name,
            meta: JSONUtils.getDictionaryValue(sensor.meta),
            csUploadEnabled: sensor.csUploadEnabled,
            csDownloadEnabled: sensor.csDownloadEnabled,
            persistLocally: sensor.persistLocally,
            userId: sensor.userId,
            source: sensor.source,
            dataType: sensor.dataType,
            csDataPointsDownloaded: sensor.csDataPointsDownloaded
        )
    }
    
    public func insertDataPoint(value: AnyObject, _ date: NSDate) -> Bool {
        let dataPoint = DataPoint(sensorId: DatabaseHandler.getNextKeyForSensor(), value: JSONUtils.stringify(value), date: date)
        do{
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            return true
        } catch {
            NSLog("Failed to insert DataPoint")
            return false
        }
    }

    
    public func getDataPoints(queryOptions: QueryOptions) throws -> [DataPoint]{
        var dataPoints = [DataPoint]()
        
        do{
            dataPoints = try DatabaseHandler.getDataPoints(self.id, queryOptions)
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
