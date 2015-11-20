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
    var meta: Dictionary<String, AnyObject>
    var remoteUploadEnabled = true
    var remoteDownloadEnabled = true
    var persistLocally = true
    var userId = ""
    var source = ""
    var remoteDataPointsDownloaded = false

    init(id:Int, name: String,   meta:Dictionary<String, AnyObject> = Dictionary<String, AnyObject>(), remoteUploadEnabled: Bool = false, remoteDownloadEnabled: Bool = false,
        persistLocally: Bool = false, userId: String, source: String, remoteDataPointsDownloaded: Bool) {
            
        self.id = id
        self.name = name
        self.meta = meta
        self.remoteUploadEnabled = remoteUploadEnabled
        self.remoteDownloadEnabled = remoteDownloadEnabled
        self.persistLocally = persistLocally
        self.userId = userId
        self.source = source
        self.remoteDataPointsDownloaded = remoteDataPointsDownloaded
    }
    
    convenience init(name: String, source: String, sensorConfig: SensorConfig = SensorConfig(), userId: String, remoteDataPointsDownloaded: Bool) {
        self.init(
            id: 0,
            name: name,
            meta: sensorConfig.meta,
            remoteUploadEnabled: sensorConfig.uploadEnabled,
            remoteDownloadEnabled: sensorConfig.downloadEnabled,
            persistLocally: sensorConfig.persist,
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
        applyNewConfig(sensorConfig)
        try DatabaseHandler.updateSensor(self)
    }
    
    /**
    * Delete data from the Local Storage and Common Sense for this sensor
    * DataPoints will be immediately removed locally, and an event (class DataDeletionRequest)
    * is scheduled for the next synchronization round to delete them from Common Sense.
    * @param startTime The start time in epoch milliseconds. nil for not specified.
    * @param endTime The end time in epoch milliseconds. nil for not specified.
    * //TODO add a list of potential exceptions
    **/
    public func deleteDataPoints(startTime startTime : NSDate? = nil, endTime: NSDate? = nil) throws {
        var queryOptions = QueryOptions()
        queryOptions.startTime = startTime
        queryOptions.endTime = endTime
        try DatabaseHandler.deleteDataPoints(self.id, queryOptions)
        try DatabaseHandler.createDataDeletionRequest(sourceName: self.source, sensorName: self.name, startTime: startTime, endTime: endTime)
    }
    
    
    // MARK: helper functions
    
    func applyNewConfig(sensorConfig: SensorConfig){
        self.remoteDownloadEnabled = sensorConfig.downloadEnabled
        self.remoteUploadEnabled = sensorConfig.uploadEnabled
        self.meta = sensorConfig.meta
        self.persistLocally = sensorConfig.persist
    }
}
