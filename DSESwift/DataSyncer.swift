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
class DataSyncer : NSObject {

    // only used for the default parameters
    let config = DSEConfig()
    
    var syncRate: Double
    var persistentPeriod: Double
    var enablePeriodicSync: Bool
    
    var timer:NSTimer?
    let data_syncer_process_queue = dispatch_queue_create(DSEConstants.DATASYNCER_PROCESS_QUEUE_ID, nil)
    
    var delegate: DataSyncerDelegate?
    
    private(set) var initialized = false

    // the key for the string should be <source>:<sensor>
    override init () {
        self.syncRate = self.config.syncInterval!
        self.persistentPeriod = self.config.localPersistancePeriod!
        self.enablePeriodicSync = self.config.enablePeriodicSync!
    }
    
    /**
     * this will error check it's own configuration
     */
    func setConfig(config: DSEConfig) throws -> (configChanged: Bool, syncInterval: Double, localPersistancePeriod: Double, enablePeridicSync: Bool) {
        var configChanged = false
        if let syncInterval = config.syncInterval {
            if (syncInterval < 0) {throw DSEError.InvalidSyncRate}
            configChanged = configChanged || self.syncRate != syncInterval
            self.syncRate = syncInterval
        }
        
        if let localPersistancePeriod = config.localPersistancePeriod {
            if (localPersistancePeriod < 0) {throw DSEError.InvalidPersistentPeriod}
            configChanged = configChanged || self.persistentPeriod != localPersistancePeriod
            self.persistentPeriod = localPersistancePeriod
        }
        
        if let enablePeriodicSync = config.enablePeriodicSync {
            configChanged = configChanged || self.enablePeriodicSync != enablePeriodicSync
            self.enablePeriodicSync = enablePeriodicSync
        }
        
        // return new values that will be used
        return (configChanged, self.syncRate, self.persistentPeriod, self.enablePeriodicSync)
    }
    
    func initialize()  {
        dispatch_async(data_syncer_process_queue, {
            do{
                try self.downloadSensorProfiles()
                try self.downloadSensorsFromRemote()
                print("DSE Initialization Completed")
                self.initialized = true
                self.delegate?.onInitializationCompleted()
            }catch{
                self.delegate?.onInitializationFailed(error)
            }
        })
    }
    
    func startPeriodicSync() {
        dispatch_async(data_syncer_process_queue, {
            if (self.initialized){
                if (self.enablePeriodicSync){
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: "sync", userInfo: nil, repeats: true);
                    self.timer!.fire()
                }else{
                    print("Periodic Sync is disabled.")
                }
            }else{
                print("DSE is not initialized")
            }
        })
    }

    func stopPeriodicSync(){
        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = nil
        } else {
            print("timer is already nil")
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
            print("ERROR: DataSyncer - There has been an error during syncing:", error)
            self.delegate?.onSyncFailed(error)
        })
    }
    
    func downloadSensorProfiles() throws {
        let sensorProfiles = try SensorDataProxy.getSensorProfiles()
        for ( _ ,subJson):(String, JSON) in sensorProfiles {
            let sensorName = subJson[DSEConstants.SENSOR_PROFILE_KEY_NAME].stringValue
            let dataStructure = JSONUtils.stringify(subJson[DSEConstants.SENSOR_PROFILE_KEY_STRUCTURE])
            try DatabaseHandler.createOrUpdateSensorProfile(sensorName, dataStructure: dataStructure)
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
            for sensor in sensors {
                if !DatabaseHandler.hasSensor(sensor.source, sensorName: sensor.name) {
                    try DatabaseHandler.insertSensor(sensor)
                } else {
                    try DatabaseHandler.updateSensor(sensor)
                }
            }
            
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
                    //update download status of the sensor
                    sensor.remoteDataPointsDownloaded = true
                    try DatabaseHandler.updateSensor(sensor)
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
                // upload datapoints that are not yet uploaded to remote
                let dataPointsToUpload = try getDataPointsToUpload(sensor)
                let dataArray = try JSONUtils.getJSONArray(dataPointsToUpload, sensorName: sensor.name)
                try SensorDataProxy.putSensorData(sourceName: sensor.source, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
                // Update the existsInRemote status of datapoints to true
                for datapoint in dataPointsToUpload {
                    datapoint.existsInRemote = true
                    try DatabaseHandler.insertOrUpdateDataPoint(datapoint)
                }
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
        let limit = DSEConstants.DEFAULT_REMOTE_QUERY_LIMIT
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
            isCompleted = (sensorData["data"].count != limit)
            if (!isCompleted){
                startBoundaryForNextQuery = getTimestampOfLastDataPoint(sensorData)
            }
        } while (!isCompleted)
    }
    
    
    private func getTimestampOfLastDataPoint(sensorData: JSON) -> NSDate?{
        let data = sensorData["data"]
        let lastDataPoint = data[data.count-1]
        return NSDate(timeIntervalSince1970: lastDataPoint["time"].doubleValue)
    }
    
    private func getDataPointsToUpload(sensor: Sensor) throws -> Array<DataPoint> {
        var queryOptions = QueryOptions()
        queryOptions.existsInRemote = false
        return try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
    }
    
    private func getSensorsInLocal() -> Array<Sensor>{
        var allSensorsInLocal = Array<Sensor>()
        let sources = DatabaseHandler.getSources()
        for source in sources{
            allSensorsInLocal.appendContentsOf(DatabaseHandler.getSensors(source))
        }
        return allSensorsInLocal
    }
    
    private func getSensorsFromRemote() throws -> Array<Sensor>{
        let downloadedArray = try SensorDataProxy.getSensors()
        var sensors = Array<Sensor>()
        for anyObj in downloadedArray.arrayObject! {
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
    
    private func insertSensorDataIntoLocalDB(sensorData: JSON, sensorId: Int) throws {
        for (_ ,subJson):(String, JSON) in sensorData["data"] {
            //Do something you want
            let value = JSONUtils.stringify(subJson["value"])
            let time = NSDate(timeIntervalSince1970: subJson["time"].doubleValue / 1000.0)
            let dataPoint = DataPoint(sensorId: sensorId, value: value, time: time)
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }
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
            }else{
                try deleteDataForSensor(sensor.id)
            }
        }
    }
    
    private func deleteDataIfExistsInRemoteAndExpired(id:Int) throws {
        let persistentBoundary = NSDate().dateByAddingTimeInterval (-1 * persistentPeriod)
        var queryOptions = QueryOptions()
        queryOptions.endTime = persistentBoundary
        queryOptions.existsInRemote = true
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    private func deleteDataIfExistsInRemote(id:Int) throws {
        var queryOptions = QueryOptions()
        queryOptions.existsInRemote = true
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    private func deleteDataIfExpired(id:Int) throws {
        let persistentBoundary = NSDate().dateByAddingTimeInterval (-1 * persistentPeriod)
        var queryOptions = QueryOptions()
        queryOptions.endTime = persistentBoundary
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
    private func deleteDataForSensor(id:Int) throws {
        let queryOptions = QueryOptions()
        try DatabaseHandler.deleteDataPoints(id, queryOptions)
    }
    
}
