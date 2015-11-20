//
//  DataSyncer.swift
//  SensePlatform
//
//  Created by Fei on 15/10/15.
//
//

import Foundation
import RealmSwift
import PromiseKit
import CoreLocation
import SwiftyJSON



/**
 * DataSyncer handles the synchronization between the local storage and CommonSense.
 * The syncing process is handled automatically and periodically, thus the external
 * user does not need to be aware of the data syncing process at all.
 *
 */
public class DataSyncer : NSObject {
    
    enum DataSyncerError: ErrorType{
        case InvalidPersistentPeriod
        case InvalidSyncRate
    }
    
    let SENSOR_PROFILE_KEY_NAME = "sensor_name"
    let SENSOR_PROFILE_KEY_STRUCTURE = "data_structure"
    
    let MAX_INITIALIZATION_ATTEMPTS = 5
    
    var initializationAttemps = 0

    // only used for the default parameters
    let config = DSEConfig()
    
    var syncRate: Double!
    var persistentPeriod: Double!
    
    var timer:NSTimer?
    let data_syncer_process_queue = dispatch_queue_create("nl.sense.dse.sync_process_queue", nil)
    
    var delegate: DataSyncerDelegate?
    
    private(set) var initialized = false

    // the key for the string should be <source>:<sensor>
    override init () {
        self.syncRate = self.config.syncInterval!
        self.persistentPeriod = self.config.localPersistancePeriod!
    }
    
    /**
     * this will error check it's own configuration
     */
    func setConfig(config: DSEConfig) throws -> (configChanged: Bool, syncInterval: Double, localPersistancePeriod: Double) {
        var configChanged = false
        if let syncInterval = config.syncInterval {
            if (syncInterval < 0) {throw DataSyncerError.InvalidSyncRate}
            configChanged = configChanged || self.syncRate != syncInterval
            self.syncRate = syncInterval
        }
        
        if let localPersistancePeriod = config.localPersistancePeriod {
            if (localPersistancePeriod < 0) {throw DataSyncerError.InvalidPersistentPeriod}
            configChanged = configChanged || self.persistentPeriod != localPersistancePeriod
            self.persistentPeriod = localPersistancePeriod
        }
        
        // return new values that will be used
        return (configChanged, self.syncRate, self.persistentPeriod)
    }
    
    func initialize()  {
        dispatch_async(data_syncer_process_queue, {
            do{
                try self.downloadSensorProfiles()
                print("DSE Initialization Completed")
                self.initialized = true
                self.delegate?.onInitializationCompleted()
            }catch{
                self.delegate?.onInitializationFailed(error)
            }
        })
    }
    
    func enablePeriodicSync() {
        dispatch_async(data_syncer_process_queue, {
            if (self.initialized){
                if self.timer == nil {
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: "sync", userInfo: nil, repeats: true);
                }
                self.timer!.fire()
            }else{
                print("DSE is not initialized")
            }
        })
    }

    func disablePeriodicSync(){
        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = nil
        } else {
            print("timer is nil")
        }
    }
    
    /**
     * Synchronize data in local and remote storage.
     * Is executed asynchronously.
     */
    public func sync() {
        dispatch_promise(on: data_syncer_process_queue, body:{ _ -> Promise<Void> in
            return Promise<Void> { fulfill, reject in
                print("")
                // step 1
                try self.processDeletionRequests()
                // step 2
                try self.uploadSensorDataToRemote()
                // step 3
                try self.downloadSensorsFromRemote()
                // step 4
                try self.downloadSensorsDataFromRemote()
                // step 5
                try self.cleanLocalStorage()
                fulfill()
            }
        }).then({ _ in
            self.delegate?.onSyncCompleted()
        }).error({ error in
            print(error)
            self.delegate?.onSyncFailed(error)
        })
    }
    
    func downloadSensorProfiles() throws {
        let sensorProfiles = try SensorDataProxy.getSensorProfiles()
        for ( _ ,subJson):(String, JSON) in sensorProfiles {
            let (sensorName, structure) = self.getSensorNameAndStructure(subJson)
            try DatabaseHandler.createOrUpdateSensorProfile(sensorName, dataStructure: structure)
        }
    }

    
    func processDeletionRequests() throws {
        let dataDeletionRequests = DatabaseHandler.getDataDeletionRequests()
        for request in dataDeletionRequests {
            try SensorDataProxy.deleteSensorData(sourceName: request.sourceName, sensorName: request.sensorName, startTime: request.startTime, endTime: request.endTime)
            // remove the deletion request which has been processed
            try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
        }
    }
    
    
    func downloadSensorsFromRemote() throws {
        do{
            let sensors = try getSensorsFromRemote()
            try insertSensorsIntoLocal(sensors)
            //notify
            self.delegate?.onSensorsDownloadCompleted()
        }catch {
            self.delegate?.onSensorDataDownloadFailed(error)
            throw error
        }

    }
    
    func downloadSensorsDataFromRemote() throws {
        do{
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal{
                if (sensor.remoteDownloadEnabled){
                    try downloadAndStoreDataForSensor(sensor)
                    try updateDownloadStatusForSensor(sensor)
                }
            }
            self.delegate?.onSensorDataDownloadCompleted()
        }catch{
            self.delegate?.onSensorDataDownloadFailed(error)
            throw error
        }
    }

    func uploadSensorDataToRemote() throws {
        let sensorsInLocal = getSensorsInLocal()
        
        for sensor in sensorsInLocal {
            if (sensor.remoteUploadEnabled){
                let dataPointsToUpload = try getDataPointsToUpload(sensor)
                try uploadDataPointsForSensor(dataPointsToUpload, sensor: sensor)
                try updateUploadStatusForDataPoints(dataPointsToUpload)
            }
        }
    }
    
    func cleanLocalStorage() throws {
        let sensorsInLocal = getSensorsInLocal()
        for sensor in sensorsInLocal {
            try purgeDataForSensor(sensor)
        }
    }
    
    // MARK: Helper functions
    private func downloadAndStoreDataForSensor(sensor: Sensor) throws{
        let limit = 1000
        var isCompleted = false
        let persistentBoundary = NSDate().dateByAddingTimeInterval (-1 * persistentPeriod)
        var startBoundaryForNextQuery: NSDate?
        
        // download and store data. Loop stops when the number of datapoints is not equal to the limit specified in the request.
        repeat{
            var queryOptions = QueryOptions()
            queryOptions.limit = limit
            queryOptions.startTime = (startBoundaryForNextQuery == nil) ? persistentBoundary : startBoundaryForNextQuery
            let sensorData = try SensorDataProxy.getSensorData(sourceName: sensor.source, sensorName: sensor.name)
            try insertSensorDataIntoLocalDB(sensorData, sensorId: sensor.id)
            
            //check if download is completed, if not prepare for the next download
            isCompleted = isDataDownloadCompleted(sensorData, limit: limit)
            if (!isCompleted){
                startBoundaryForNextQuery = getTimestampOfLastDataPoint(sensorData)
            }
        } while (!isCompleted)
    }
    
    private func isDataDownloadCompleted(sensorData: JSON, limit: Int) -> Bool{
        return (sensorData["data"].count != limit)
    }
    
    private func getTimestampOfLastDataPoint(sensorData: JSON) -> NSDate?{
        let data = sensorData["data"]
        let lastDataPoint = data[data.count-1]
        return NSDate(timeIntervalSince1970: lastDataPoint["time"].doubleValue)
    }
    
    private func updateDownloadStatusForSensor(sensor: Sensor) throws {
        sensor.remoteDataPointsDownloaded = true
        try DatabaseHandler.updateSensor(sensor)
    }
    
    private func getDataPointsToUpload(sensor: Sensor) throws -> Array<DataPoint> {
        var queryOptions = QueryOptions()
        queryOptions.existsInRemote = false
        return try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
    }
    
    private func uploadDataPointsForSensor(dataPoints: Array<DataPoint>, sensor: Sensor) throws {
        let dataArray = try DataSyncer.getJSONArray(dataPoints, sensorName: sensor.name)
        try SensorDataProxy.putSensorData(sourceName: sensor.source, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
    }
    
    private func updateUploadStatusForDataPoints(dataPoints: Array<DataPoint>) throws {
        for datapoint in dataPoints {
            datapoint.existsInRemote = true
            try DatabaseHandler.insertOrUpdateDataPoint(datapoint)
        }
    }
    
    private func getSensorsInLocal() -> Array<Sensor>{
        var allSensorsInLocal = Array<Sensor>()
        let sources = DatabaseHandler.getSources()
        for source in sources{
            allSensorsInLocal.appendContentsOf(DatabaseHandler.getSensors(source))
        }
        return allSensorsInLocal
    }
    
    private func insertSensorsIntoLocal(sensors: Array<Sensor>) throws {
        for sensor in sensors {
            if !DatabaseHandler.hasSensor(sensor.source, sensorName: sensor.name) {
                try DatabaseHandler.insertSensor(sensor)
            } else {
                try DatabaseHandler.updateSensor(sensor)
            }
        }
    }
    
    private func getSensorsFromRemote() throws -> Array<Sensor>{
        let downloadedArray = try SensorDataProxy.getSensors()
        return convertAnyObjArrayToSensorArray(downloadedArray.arrayObject)
    }
    
    private func convertAnyObjArrayToSensorArray(inputArray: Array<AnyObject>?) -> Array<Sensor>{
        var sensors = Array<Sensor>()
        for anyObj in inputArray! {
            sensors.append(convertAnyObjectToSensor(anyObj))
        }
        return sensors
    }
    
    private func convertAnyObjectToSensor(anyObj: AnyObject) -> Sensor{
        let sensorDict = anyObj as! Dictionary<String, AnyObject>
        let sourceName = sensorDict["source_name"] as! String
        let sensorName = sensorDict["sensor_name"] as! String
        let metaDict = sensorDict["meta"] as! Dictionary<String, AnyObject>
        var sensorConfig = SensorConfig()
        sensorConfig.meta = metaDict
        
        return Sensor(name: sensorName, source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
    }
    
    func insertSensorDataIntoLocalDB(sensorData: JSON, sensorId: Int) throws {
        for (_ ,subJson):(String, JSON) in sensorData["data"] {
            //Do something you want
            let value = JSONUtils.stringify(subJson["value"])
            let time = NSDate(timeIntervalSince1970: subJson["time"].doubleValue / 1000.0)
            let dataPoint = DataPoint(sensorId: sensorId, value: value, time: time)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }
    }
    
    func deleteDataIfExistsInRemoteAndExpired(id:Int) throws {
        let persistentBoundary = NSDate().dateByAddingTimeInterval (-1 * persistentPeriod)
        var queryOptions = QueryOptions()
        queryOptions.endTime = persistentBoundary
        queryOptions.existsInRemote = true
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    func deleteDataIfExistsInRemote(id:Int) throws {
        var queryOptions = QueryOptions()
        queryOptions.existsInRemote = true
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    func deleteDataIfExpired(id:Int) throws {
        let persistentBoundary = NSDate().dateByAddingTimeInterval (-1 * persistentPeriod)
        var queryOptions = QueryOptions()
        queryOptions.endTime = persistentBoundary
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    static func getJSONArray(dataPoints: Array<DataPoint>, sensorName: String) throws -> JSON{
        let profile = try DatabaseHandler.getSensorProfile(sensorName)!
        let type = try getTypeFromDataStructure(profile.dataStructure)
        switch (type){
            case "integer":
                return JSONUtils.convertArrayOfDataPointIntoJSONArrayWithIntValue(dataPoints)
            case "number":
                return JSONUtils.convertArrayOfDataPointIntoJSONArrayWithDoubleValue(dataPoints)
            case "bool":
                return JSONUtils.convertArrayOfDataPointIntoJSONArrayWithBoolValue(dataPoints)
            case "string":
                return JSONUtils.convertArrayOfDataPointIntoJSONArrayWithStringValue(dataPoints)
            case "object":
                return JSONUtils.convertArrayOfDataPointIntoJSONArrayWithDictionaryValue(dataPoints)
            default:
                throw DSEError.UnknownDataType
        }
    }
    
    
    func getSensorNameAndStructure(json: JSON) -> (String, String){
        let sensorName = json[SENSOR_PROFILE_KEY_NAME].stringValue
        let dataStructure = json[SENSOR_PROFILE_KEY_STRUCTURE].rawString(options: NSJSONWritingOptions(rawValue: 0))!
        return (sensorName, dataStructure)
    }
    
    private static func getTypeFromDataStructure(structure: String) throws -> String {
        let data :NSData = structure.dataUsingEncoding(NSUTF8StringEncoding)!
        let json :Dictionary = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as! [String:AnyObject]
        
        return json["type"] as! String
    }
    
    private func purgeDataForSensor(sensor:Sensor) throws {
        // delete Data if matches the criteria
        if sensor.remoteUploadEnabled {
            if sensor.persistLocally {
                try deleteDataIfExistsInRemoteAndExpired(sensor.id)
            }else{
                try deleteDataIfExistsInRemote(sensor.id)
            }
        } else {
            if sensor.persistLocally {
                try deleteDataIfExpired(sensor.id)
            }
        }
    }
    
    private func getParser(datatype: String) throws -> BaseValueParser{
        switch (datatype){
            case "integer":
                return IntValueParser()
            case "number":
                return DoubleValueParser()
            case "bool":
                return BoolValueParser()
            case "string":
                return StringValueParser()
            case "object":
                return DictionaryValueParser()
            default:
                throw DSEError.UnknownDataType
        }
    }
    
    
}
