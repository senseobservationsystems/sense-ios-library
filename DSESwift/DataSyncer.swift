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

class DataSyncer {
    
    enum DataSyncerError: ErrorType{
        case InvalidPersistentPeriod
        case InvalidSyncRate
    }
    
    static let SOURCE = "aim-ios-sdk"
    let SENSOR_PROFILE_KEY_NAME = "sensor_name"
    let SENSOR_PROFILE_KEY_STRUCTURE = "data_structure"

    let DEFAULT_SYNC_RATE: Double = 30 * 60    // 30 mins in secs
    let DEFAULT_PERSISTENT_PERIOD: Double = 30 * 24 * 60 * 60     // 30 days in secs
    
    var syncRate: Double!
    var persistentPeriod: Double!
    var config = DSEConfig()
    
    var proxy:SensorDataProxy
    var timer:NSTimer?

    // the key for the string should be <source>:<sensor>
    init () {
        self.proxy = SensorDataProxy()
        self.persistentPeriod = DEFAULT_PERSISTENT_PERIOD
        self.syncRate = DEFAULT_SYNC_RATE
    }
    
    func initialize() throws{
        dispatch_promise{
            self.downloadSensorProfiles
        }
    }
    
    func setConfig(config: DSEConfig) {
        self.config = config
        self.syncRate = self.config.syncInterval!
        self.persistentPeriod = self.config.localPersistancePeriod!
        self.proxy.setConfig(self.config)
    }
    
    func enablePeriodicSync(syncRate: Double?) {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: Selector("synchronize"), userInfo: nil, repeats: true);
        }
        timer!.fire()
    }

    func disablePeriodicSync(){
        timer!.invalidate()
    }

    
    func doPeriodicSync(useMainThread: Bool = false) throws {
        var queue = dispatch_get_main_queue()
        if (useMainThread == false) {
            queue = dispatch_queue_create("DSEDataSyncerPeriodicSync", nil)
        }
        
        dispatch_promise(on: queue, body: {
            return try self.processDeletionRequests()
        }).then (on: queue, {
            return try self.downloadSensorsFromRemote()
        }).then (on: queue, {
            return try self.downloadSensorsDataFromRemote()
        }).then (on: queue, {
            return try self.uploadSensorDataToRemote()
        }).then (on: queue, {
            return try self.cleanUpLocalStorage()
        }).error({error in
            print(error)
        })
    }

    
    func downloadSensorProfiles() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let sensorProfiles = try proxy.getSensorProfiles()
            for ( _ ,subJson):(String, JSON) in sensorProfiles {
                try DatabaseHandler.createOrUpdateSensorProfile(subJson[SENSOR_PROFILE_KEY_NAME].stringValue, dataStructure: subJson[SENSOR_PROFILE_KEY_STRUCTURE].stringValue)
            }
            
            // TODO: Change the status of DSE
            fulfill()
        }
    }
    
    func processDeletionRequests() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
            for request in dataDeletionRequests {
                try proxy.deleteSensorData(sourceName: request.sourceName, sensorName: request.sensorName, startTime: request.startTime, endTime: request.endTime)
                // remove the deletion request which has been processed
                try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
            }
            fulfill()
        }
    }
    
    
    func downloadSensorsFromRemote() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let sensors = try getSensorsFromRemote()
            
            try insertSensorsIntoLocalDB(sensors)
            fulfill()
        }
    }
    
    func downloadSensorsDataFromRemote() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal{
                if (sensor.remoteDownloadEnabled){
                    try downloadAndStoreDataForSensor(sensor)
                    try updateDownloadStatusForSensor(sensor)
                }
            }
            fulfill()
        }
    }

    func uploadSensorDataToRemote() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal {
                if (sensor.remoteUploadEnabled){
                    let unuploadedDataPoints = try getUnuploadedDataPoints(sensor)
                    try uploadDataPointsForSensor(unuploadedDataPoints, sensor: sensor)
                    try updateUploadStatusForDataPoints(unuploadedDataPoints)
                }
            }
            fulfill()
        }
    }
    
    func cleanUpLocalStorage() throws -> Promise<Void> {
        return Promise{fulfill, reject in
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal {
                try purgeDataForSensor(sensor)
            }
            fulfill()
        }
    }
    
    // MARK: Helper functions
    private func downloadAndStoreDataForSensor(sensor: Sensor) throws{
        let limit = 1000
        var isDataDownloadCompleted = false
        // download and store data. Loop stops when the number of datapoints is not equal to the limit specified in the request.
        repeat{
            var queryOptions = QueryOptions()
            queryOptions.limit = limit
            let sensorData = try proxy.getSensorData(sourceName: sensor.source, sensorName: sensor.name)
            try insertSensorDataIntoLocalDB(sensorData, sensorId: sensor.id)
            isDataDownloadCompleted = (sensorData.count != limit)
        } while (!isDataDownloadCompleted)
    }
    
    private func updateDownloadStatusForSensor(sensor: Sensor) throws {
        sensor.remoteDataPointsDownloaded = true
        try DatabaseHandler.updateSensor(sensor)
    }
    
    private func getUnuploadedDataPoints(sensor: Sensor) throws -> Array<DataPoint> {
        var queryOptions = QueryOptions()
        queryOptions.existsInRemote = false
        return try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
    }
    
    private func uploadDataPointsForSensor(dataPoints: Array<DataPoint>, sensor: Sensor) throws {
        let dataArray = try getJSONArray(dataPoints, sensorName: sensor.name)
        try proxy.putSensorData(sourceName: DataSyncer.SOURCE, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
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
    
    private func insertSensorsIntoLocalDB(sensors: Array<Sensor>) throws {
        for sensor in sensors {
            if !DatabaseHandler.hasSensor(sensor.source, sensorName: sensor.name) {
                try DatabaseHandler.insertSensor(sensor)
            } else {
                try DatabaseHandler.updateSensor(sensor)
            }
        }
    }
    
    private func getSensorsFromRemote() throws -> Array<Sensor>{
        let downloadedArray = try proxy.getSensors()
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
            let value = subJson["value"].stringValue
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
    
    private func getJSONArray(dataPoints: Array<DataPoint>, sensorName: String) throws -> Array<AnyObject>{
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
    
    
    private func getTypeFromDataStructure(structure: String) throws -> String {
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
