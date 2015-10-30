//
//  Sensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation
import VVJSONSchemaValidation


let kCSDATA_TYPE_STRING = "string"
let kCSDATA_TYPE_JSON = "json"
let kCSDATA_TYPE_INTEGER = "integer"
let kCSDATA_TYPE_FLOAT = "float"
let kCSDATA_TYPE_BOOL = "bool"

public enum SortOrder{
    case Asc
    case Desc
}

public enum DSEError: ErrorType{
    case IncorrectDataStructure
}


/**
* //TODO: Add documentation
*
*/
public class Sensor{
    var id = -1
    var name = ""
    var meta: Dictionary<String, AnyObject>?
    var remoteUploadEnabled = false
    var remoteDownloadEnabled = false
    var persistLocally = true
    var userId = ""
    var source = ""
    var remoteDataPointsDownloaded = false

    init(id:Int, name: String,   meta:Dictionary<String, AnyObject>?, remoteUploadEnabled: Bool? = false, remoteDownloadEnabled: Bool? = false,
        persistLocally: Bool? = true, userId: String, source: String, remoteDataPointsDownloaded: Bool) {
            
        self.id = id
        self.name = name
        self.meta = meta
        self.remoteUploadEnabled = remoteUploadEnabled!
        self.remoteDownloadEnabled = remoteDownloadEnabled!
        self.persistLocally = persistLocally!
        self.userId = userId
        self.source = source
        self.remoteDataPointsDownloaded = remoteDataPointsDownloaded
    }
    
    convenience init(name: String, source: String, sensorConfig: SensorConfig? = nil, userId: String, remoteDataPointsDownloaded: Bool) {
        self.init(
            id: DatabaseHandler.getNextKeyForSensor(),
            name: name,
            meta: sensorConfig?.meta,
            remoteUploadEnabled: sensorConfig?.uploadEnabled,
            remoteDownloadEnabled: sensorConfig?.downloadEnabled,
            persistLocally: sensorConfig?.persist,
            userId: userId,
            source: source,
            remoteDataPointsDownloaded: remoteDataPointsDownloaded
        )
    }
    
    convenience init(_ sensor: RLMSensor) {
        self.init(
            id: sensor.id,
            name: sensor.name,
            meta: JSONUtils.getDictionaryValue(sensor.meta),
            remoteUploadEnabled: sensor.remoteUploadEnabled,
            remoteDownloadEnabled: sensor.remoteDownloadEnabled,
            persistLocally: sensor.persistLocally,
            userId: sensor.userId,
            source: sensor.source,
            remoteDataPointsDownloaded: sensor.remoteDataPointsDownloaded
        )
    }
    
    public func insertDataPoint(value: AnyObject, _ time: NSDate) throws {
        let dataStructure = try DatabaseHandler.getSensorProfile(self.name)?.dataStructure
        if !JSONUtils.validateValue(value, schema: dataStructure!){
            throw DSEError.IncorrectDataStructure
        }
        
        let dataPoint = DataPoint(sensorId: self.id)
        
        let stringifiedValue = JSONUtils.stringify(value)
        dataPoint.setValue(stringifiedValue)
        dataPoint.setTime(time)
        
        try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
    }


    
    public func getDataPoints(queryOptions: QueryOptions) throws -> [DataPoint]{
        var dataPoints = [DataPoint]()
        
        dataPoints = try DatabaseHandler.getDataPoints(self.id, queryOptions)

        return dataPoints
    }
    
    /**
    * Apply configs for the sensor.
    * fields in `options` which are `null` will be ignored.
    * @param options
    * @return Returns the applied options.
    */
    public func setSensorConfig(sensorConfig: SensorConfig) throws {
        do{
            let sensor = try DatabaseHandler.getSensor(self.source, self.name)
            let updatedSensor = getSensorWithUpdatedConfig(sensor, sensorConfig)
            try DatabaseHandler.updateSensor(updatedSensor)
        }
    }
    
    
    // MARK: helper functions
    
    func getSensorWithUpdatedConfig(sensor: Sensor, _ sensorConfig: SensorConfig) -> Sensor{
        if (sensorConfig.downloadEnabled != nil){
            sensor.remoteDownloadEnabled = sensorConfig.downloadEnabled!
        }
        if (sensorConfig.uploadEnabled != nil){
            sensor.remoteUploadEnabled = sensorConfig.uploadEnabled!
        }
        if (sensorConfig.meta != nil){
            sensor.meta = sensorConfig.meta!
        }
        if (sensorConfig.persist != nil){
            sensor.persistLocally = sensorConfig.persist!
        }
        return sensor
    }
}
