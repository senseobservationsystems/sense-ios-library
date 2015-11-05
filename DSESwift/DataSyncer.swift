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

class DataSyncer: NSObject {
    
    enum DataSyncerError: ErrorType{
        case InvalidPersistentPeriod
        case InvalidSyncRate
    }
    
    
    static let SOURCE: String = "aim-ios-sdk"
    let SENSOR_PROFILE_KEY_NAME = "sensor_name"
    let SENSOR_PROFILE_KEY_STRUCTURE = "data_structure"

    let DEFAULT_SYNC_RATE: Double = 30 * 60    // 30 mins in secs
    let DEFAULT_PERSISTENT_PERIOD: Double = 30 * 24 * 60 * 60     // 30 days in secs
    
    var syncRate: Double!
    var persistentPeriod: Double!
    
    var proxy:SensorDataProxy
    var timer:NSTimer?
    var delegates = [DataStorageEngineDelegate]()

    // the key for the string should be <source>:<sensor>
    init (proxy:SensorDataProxy) {
        self.proxy = proxy
        self.persistentPeriod = DEFAULT_PERSISTENT_PERIOD
        self.syncRate = DEFAULT_SYNC_RATE
    }
    
    func initialize() throws{
        dispatch_promise{
            self.downloadSensorProfiles
        }
    }
    
    func setPersistentPeriod(persistentPeriod:Double?) throws {
        if isValidPersistentPeriod(persistentPeriod){
            self.persistentPeriod = persistentPeriod
        } else {
            throw DataSyncerError.InvalidPersistentPeriod
        }
    }
    
    func setSyncRate(syncRate:Double?) throws {
        if isValidSyncRate(syncRate){
            self.syncRate = syncRate
        } else {
            throw DataSyncerError.InvalidSyncRate
        }
    }
    
    func enablePeriodicSync(syncRate: Double?) {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: Selector("synchronize"), userInfo: nil, repeats: true);
        }
        timer!.fire()
    }

    func disablePeriodicSync(syncRate: Double?){
        timer!.invalidate()
    }

    
    func doPeriodicSync() throws {
        dispatch_promise{
            return self.processDeletionRequests()
        }.then{ e in
            return self.downloadSensorsFromRemote()
        }.then{ e in
            return self.downloadSensorsDataFromRemote()
        }.then{ e in
            return self.uploadSensorDataToRemote
        }.then{ e in
            return self.cleanUpLocalStorage
        }
    }

    
    internal func downloadSensorProfiles() throws {
        let sensorProfiles = try proxy.getSensorProfiles()
        for sensorProfile in sensorProfiles!{
            let profileDict = sensorProfile as! Dictionary<String, AnyObject>
            try DatabaseHandler.createOrUpdateSensorProfile(profileDict[SENSOR_PROFILE_KEY_NAME] as! String, dataStructure: JSONUtils.stringify(profileDict[SENSOR_PROFILE_KEY_STRUCTURE]!))
        }
        
        // invoke delegates
        for delegate in delegates{
            delegate.onDSEReady()
        }
        
        // TODO: Change the status of DSE
    }
    
    internal func processDeletionRequests() -> ErrorType? {
        do{
            let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
            for request in dataDeletionRequests {
                try proxy.deleteSensorData(sourceName: request.sourceName, sensorName: request.sensorName, startTime: request.startTime, endTime: request.endTime)
                // remove the deletion request which has been processed
                try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
            }
            return nil
        }catch{
            return error
        }
    }
    
    internal func downloadSensorsFromRemote() -> ErrorType?  {
        do{
            let sensors = try getSensorsFromRemote()
            
            try insertSensorsIntoLocalDB(sensors)
            // invoke delegates
            for delegate in delegates{
                delegate.onSensorsDownloaded(sensors)
            }
            return nil
        }catch{
            return error
        }
    }
    
    internal func downloadSensorsDataFromRemote() -> ErrorType?  {
        do{
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal{
                if (sensor.remoteDownloadEnabled){
                    try downloadAndStoreDataForSensor(sensor)
                    try updateDownloadStatusForSensor(sensor)
                }
            }
            return nil
        } catch {
            return error
        }
    }

    internal func uploadSensorDataToRemote() -> ErrorType? {
        do {
            let sensorsInLocal = getSensorsInLocal()
            for sensor in sensorsInLocal {
                if (sensor.remoteUploadEnabled){
                    let unuploadedDataPoints = try getUnuploadedDataPoints(sensor)
                    try uploadDataPointsForSensor(unuploadedDataPoints, sensor: sensor)
                    try updateUploadStatusForDataPoints(unuploadedDataPoints)
                }
            }
        } catch {
            return error
        }
        return nil
    }
    
    internal func cleanUpLocalStorage() -> ErrorType? {
        let sensorsInLocal = getSensorsInLocal()
        do{
            for sensor in sensorsInLocal {
                try purgeDataForSensor(sensor)
            }
        } catch {
            return error
        }
        return nil
    }
    
    // MARK: Helper functions
    private func downloadAndStoreDataForSensor(sensor: Sensor) throws{
        let limit = 1000
        var isDataDownloadCompleted : Bool = false
        // download and store data. Loop stops when the number of datapoints is not equal to the limit specified in the request.
        repeat{
            var queryOptions = QueryOptions()
            queryOptions.limit = limit
            let sensorData = try proxy.getSensorData(sourceName: sensor.source, sensorName: sensor.name)
            try insertSensorDataIntoLocalDB(sensorData!, sensorId: sensor.id)
            isDataDownloadCompleted = (sensorData!.count != limit)
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
        return convertAnyObjArrayToSensorArray(downloadedArray)
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
    
    func insertSensorDataIntoLocalDB(sensorData: Dictionary<String, AnyObject>, sensorId: Int) throws {
        let dataArray = sensorData["data"] as! Array<AnyObject>
        for data in dataArray{
            // convert AnyObject to DataPoint
            let dataDict = data as! Dictionary<String, AnyObject>
            let value = JSONUtils.stringify(dataDict["value"])
            let time = NSDate(timeIntervalSince1970: dataDict["time"] as! Double / 1000)
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
    
    private func isValidSyncRate(syncRate: Double?) -> Bool{
        if (syncRate != nil) && (syncRate > 0){
            return true
        } else {
            return false
        }
    }
    
    private func isValidPersistentPeriod(peristentPeriod: Double?) -> Bool{
        if (persistentPeriod != nil) && (persistentPeriod > 0){
            return true
        } else {
            return false
        }
    }
    
}
