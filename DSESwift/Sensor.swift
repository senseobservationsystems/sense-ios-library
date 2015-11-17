//
//  Sensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation
import VVJSONSchemaValidation
import SwiftyJSON


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
    case UnknownDataType
}


/**
* //TODO: Add documentation
*
*/
public class Sensor{
    var id = -1
    var name = ""
    var meta: Dictionary<String, AnyObject>?
    var remoteUploadEnabled = true
    var remoteDownloadEnabled = true
    var persistLocally = true
    var userId = ""
    var source = ""
    var remoteDataPointsDownloaded = false

    init(id:Int, name: String,   meta:Dictionary<String, AnyObject>?, remoteUploadEnabled: Bool? = true, remoteDownloadEnabled: Bool? = true,
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
            id: 0,
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
    
    /**
     * Inserts or updates a single data point for a sensor.
     * @param value: value of the dataPoint
     * @param time: time of the dataPoint
     * Throws an Exception if saving the value fails.
     **/
    public func insertOrUpdateDataPoint(value: AnyObject, _ time: NSDate) throws {
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


    /**
     * Returns an array of datapoints
     *@param queryOptions: options for the data points query.
     *@return List<DataPoint> containing the queried data points.
     * //TODO add a list of potential exceptions
     **/
    public func getDataPoints(queryOptions: QueryOptions) throws -> [DataPoint]{
        return try DatabaseHandler.getDataPoints(self.id, queryOptions)
    }
    
    /**
    * Apply configs for the sensor.
    * fields in `options` which are `null` will be ignored.
    * @param options
    * @return Returns the applied options.
    *  //TODO add a list of potential exceptions
    */
    public func setSensorConfig(sensorConfig: SensorConfig) throws {
        let sensor = try DatabaseHandler.getSensor(self.source, self.name)
        let updatedSensor = getSensorWithUpdatedConfig(sensor, sensorConfig)
        try DatabaseHandler.updateSensor(updatedSensor)
    }
    
    /**
    * Delete data from the Local Storage and Common Sense for this sensor
    * DataPoints will be immediately removed locally, and an event (class DataDeletionRequest)
    * is scheduled for the next synchronization round to delete them from Common Sense.
    * @param startTime The start time in epoch milliseconds. nil for not specified.
    * @param endTime The end time in epoch milliseconds. nil for not specified.
    * //TODO add a list of potential exceptions
    **/
    func deleteDataPoints(startTime : NSDate?, endTime: NSDate?) throws {
        var queryOptions = QueryOptions()
        queryOptions.startTime = startTime
        queryOptions.endTime = endTime
        try DatabaseHandler.deleteDataPoints(self.id, queryOptions)
        try DatabaseHandler.createDataDeletionRequest(sourceName: self.source, sensorName: self.name, startTime: startTime, endTime: endTime)
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
