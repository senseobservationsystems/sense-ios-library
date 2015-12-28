//
//  DataSyncer.swift
//  SensePlatform
//
//  Created by Fei on 15/10/15.
//
//

import Foundation
import RealmSwift
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

    // the key for the string should be <source>:<sensor>
    override init () {
        self.syncRate = self.config.syncInterval
        self.persistentPeriod = self.config.localPersistancePeriod
        self.enablePeriodicSync = self.config.enablePeriodicSync
    }
    
    /**
     * this will error check it's own configuration
     */
    func setConfig(config: DSEConfig) throws -> (configChanged: Bool, syncInterval: Double, localPersistancePeriod: Double, enablePeridicSync: Bool) {
        var configChanged = false
        
        let syncInterval = config.syncInterval
        if (syncInterval < 0) {throw DSEError.InvalidSyncRate}
        configChanged = configChanged || self.syncRate != syncInterval
        self.syncRate = syncInterval
        
        let localPersistancePeriod = config.localPersistancePeriod
        if (localPersistancePeriod < 0) {throw DSEError.InvalidPersistentPeriod}
        configChanged = configChanged || self.persistentPeriod != localPersistancePeriod
        self.persistentPeriod = localPersistancePeriod
        
        let enablePeriodicSync = config.enablePeriodicSync
        configChanged = configChanged || self.enablePeriodicSync != enablePeriodicSync
        self.enablePeriodicSync = enablePeriodicSync
        
        // return new values that will be used
        return (configChanged, self.syncRate, self.persistentPeriod, self.enablePeriodicSync)
    }
    
    /**
     * Initialize DataSyncer by downloading sensor profile and sensors from remote.
     **/
    func initialize()  {
        dispatch_async(dispatch_get_main_queue(), {
            do{
                try self.downloadSensorProfiles()
                try self.downloadSensorsFromRemote()
                print("DSE Initialization Completed")
                self.delegate?.onInitializationCompleted()
            }catch{ let e = error as! DSEError
                self.delegate?.onInitializationFailed(e)
            }
        })
    }
    
    /**
     * start the timer for the periodic syncing.
     **/
    func startPeriodicSync() {
        dispatch_async(dispatch_get_main_queue(), {
            NSLog("--- Start PeriodicSync")
            if (!self.areSensorProfilesPopulated()){
                NSLog("[DataSyncer] Sensors and SensorProfiles are not initialized")
                return
            }
            if (!self.enablePeriodicSync){
                NSLog("[DataSyncer] Periodic sync is not enabled")
                return
            }
            if (self.isPeriodicSyncTimerStarted()){
                NSLog("[DataSyncer] Start periodic syncing. Scheduling sync at: %@", self.timer!.fireDate)
                return
            }
            self.timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: "periodicSync", userInfo: nil, repeats: true);
            self.timer!.fire()
        })
    }

    /**
    * stop the timer for the periodic syncing.
    **/
    func stopPeriodicSync(){
        if self.timer != nil {
            self.timer!.invalidate()
            self.timer = nil
        } else {
            print("timer is already nil")
        }
    }
    
    func isPeriodicSyncTimerStarted()-> Bool{
        if(timer != nil){
            NSLog("[DataSyncer] Sync is scheduled at: %@", self.timer!.fireDate)
            return self.timer!.valid
        }else{
            NSLog("[DataSyncer] Timer is nil")
            return false
        }
    }
    
    // called only by the timer
    func periodicSync() {
        sync()
    }

    
    /**
     * Synchronize data in local and remote storage.
     * Is executed asynchronously.
     */
    func sync(callback: DSEAsyncCallback? = nil) {
        dispatch_async(data_syncer_process_queue, {
            do{
                NSLog("[DataSyncer] sync started")
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
                NSLog("[DataSyncer] sync completed")
                if(callback != nil){
                    callback!.onSuccess()
                }
            }catch{ let e = error as! DSEError
                NSLog("--StackTrace: %@", NSThread.callStackSymbols())
                NSLog("ERROR: DataSyncer - An error occurred during syncing:%d", e.rawValue)
                if(callback != nil){
                    callback!.onFailure(e)
                }
                self.delegate?.onException(e)
            }
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
        let dataDeletionRequests = try DatabaseHandler.getDataDeletionRequests()
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
                try self.insertOrUpdateSensorIntoLocal(sensor)
            }
            
            self.delegate?.onSensorsDownloadCompleted()
        }catch { let e = error as! DSEError
            self.delegate?.onSensorDataDownloadFailed(e)
            throw error
        }

    }
    
    func downloadSensorsDataFromRemote() throws {
        do{
            let sensorsInLocal = try getSensorsInLocal()
            for sensor in sensorsInLocal{
                if (sensor.remoteDownloadEnabled){
                    try downloadAndStoreDataForSensor(sensor)
                    //update download status of the sensor
                    sensor.remoteDataPointsDownloaded = true
                    try DatabaseHandler.updateSensor(sensor)
                }
            }
            self.delegate?.onSensorDataDownloadCompleted()
        }catch{ let e = error as! DSEError
            self.delegate?.onSensorDataDownloadFailed(e)
            throw error
        }
    }

    func uploadSensorDataToRemote() throws {
        let sensorsInLocal = try getSensorsInLocal()
        for sensor in sensorsInLocal {
            if (!sensor.remoteUploadEnabled){
                break
            }
            // upload datapoints that are not yet uploaded to remote
            let dataPointsToUpload = try getDataPointsToUpload(sensor)
            // send 1000 datapoints per request
            let numOfLoops = (dataPointsToUpload.count / DSEConstants.DEFAULT_REMOTE_POST_LIMIT) + 1
            for(var startIndex = 0 ; startIndex < numOfLoops; startIndex++) {
                let slicedArray = self.getSlicedArray(dataPointsToUpload, startIndex: startIndex)
                let dataArray = try JSONUtils.getJSONArray(slicedArray, sensorName: sensor.name)
                try SensorDataProxy.putSensorData(sourceName: sensor.source, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
                // Update the existsInRemote status of datapoints to true
                for datapoint in slicedArray {
                    datapoint.existsInRemote = true
                    try DatabaseHandler.insertOrUpdateDataPoint(datapoint)
                }
            }
        }
    }
    
    func cleanLocalStorage() throws {
        let sensorsInLocal = try getSensorsInLocal()
        for sensor in sensorsInLocal {
            try purgeDataForSensor(sensor)
        }
    }
    
    func areSensorProfilesPopulated() -> Bool {
        do{
            return (try DatabaseHandler.getSensorProfiles().count > 0)
        }catch{
            return false
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
            try insertRemoteSensorDataIntoLocalDB(sensorData, sensorId: sensor.id)
            
            //check if download is completed, if not prepare for the next download
            isCompleted = (sensorData["data"].count != limit)
            if (!isCompleted){
                startBoundaryForNextQuery = getTimestampOfLastDataPoint(sensorData)
            }
        } while (!isCompleted)
    }
    
    private func getSlicedArray(array: Array<DataPoint>,startIndex: Int) -> Array<DataPoint>{
        // endIndex: remaining length from startIndex or next startIndex
        let endIndex = min(array.count - startIndex, (startIndex + 1) * DSEConstants.DEFAULT_REMOTE_POST_LIMIT)
        return Array(array[startIndex ..< endIndex])
    }
    
    private func insertOrUpdateSensorIntoLocal(sensor: Sensor) throws{
        if try !DatabaseHandler.hasSensor(sensor.source, sensorName: sensor.name) {
            do{
                try DatabaseHandler.insertSensor(sensor)
                self.delegate?.onSensorCreated(sensor.name)
            }catch DSEError.InvalidSensorName {
                print("Invalid SensorName: ", sensor.name)
            }
        } else {
            let sensorInLocal = try DatabaseHandler.getSensor(sensor.source, sensor.name)
            try DatabaseHandler.updateSensor(sensorInLocal)
        }
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
    
    private func getSensorsInLocal() throws -> Array<Sensor>{
        var allSensorsInLocal = Array<Sensor>()
        let sources = try DatabaseHandler.getSources()
        for source in sources{
            allSensorsInLocal.appendContentsOf(try DatabaseHandler.getSensors(source))
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
        
        let defaults = NSUserDefaults.standardUserDefaults()
        return Sensor(name: sensorName, source: sourceName, sensorConfig: sensorConfig, userId: defaults.stringForKey(DSEConstants.USERID_KEY)!, remoteDataPointsDownloaded: false)
    }
    
    private func insertRemoteSensorDataIntoLocalDB(sensorData: JSON, sensorId: Int) throws {
        for (_ ,subJson):(String, JSON) in sensorData["data"] {
            //Do something you want
            let value = JSONUtils.stringify(subJson["value"])
            let time = NSDate(timeIntervalSince1970: subJson["time"].doubleValue / 1000.0)
            let dataPoint = DataPoint(sensorId: sensorId, value: value, time: time, existsInRemote: true)
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
