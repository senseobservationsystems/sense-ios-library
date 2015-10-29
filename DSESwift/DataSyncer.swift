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
    static let SOURCE: String = "aim-ios-sdk"
    
    let SENSOR_PROFILE_KEY_NAME = "sensor_name"
    let SENSOR_PROFILE_KEY_STRUCTURE = "data_structure"
    
    // 30 mins in secs
    let DEFAULT_SYNC_RATE: Double = 30 * 60
    // 30 days in secs
    let DEFAULT_PERSISTENT_PERIOD: Double = 30 * 24 * 60 * 60
    
    var proxy:SensorDataProxy
    var timer:NSTimer?
    var delegates = [DataStorageEngineDelegate]()

    var syncRate: Double!
    var persistentPeriod: Double!
    var sensorConfigDict: Dictionary<String, SensorConfig>!

    // the key for the string should be <source>:<sensor>
    init (proxy:SensorDataProxy, persistPeriod:Double?, syncRate: Double?) {
        self.proxy = proxy
        self.persistentPeriod = (persistPeriod != nil) ? persistPeriod! : DEFAULT_PERSISTENT_PERIOD
        self.syncRate = (syncRate != nil) ? syncRate! : DEFAULT_SYNC_RATE
    }
    
    func enablePeriodicSync() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(self.syncRate, target: self, selector: Selector("synchronize"), userInfo: nil, repeats: true);
        }
        timer!.fire()
    }

    func disablePeriodicSync(){
        timer!.invalidate()
    }
    
    func initializeSensorProfile() throws{
        dispatch_promise{
            self.downloadSensorProfile
        }
    }
    
    func synchronize() throws {        
        dispatch_promise{
            return self.deletionInRemote
        }.then{ e in
            return self.downloadSensorsFromRemote()
        }.then{ e in
            return self.uploadToRemote
        }.then{ e in
            return self.cleanUpLocalStorage
        }
    }

    func downloadSensorProfile() throws {
        let sensorProfiles = try proxy.getSensorProfiles()
        
        for sensorProfile in sensorProfiles!{
            let profileDict = sensorProfile as! Dictionary<String, String>
            try DatabaseHandler.createOrUpdateSensorProfile(profileDict[SENSOR_PROFILE_KEY_NAME]!, dataStructure: profileDict[SENSOR_PROFILE_KEY_STRUCTURE]!)
        }
    }
    
    func deletionInRemote() -> ErrorType? {
        do{
            let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
            try processDeletionRequests(dataDeletionRequests)
            return nil
        }catch{
            return error
        }
    }
    
    func downloadSensorsFromRemote() -> ErrorType?  {
        var sensors: Array<AnyObject>?
        //get Sensors From Remote and store them in the local storage
        do{
            sensors = try proxy.getSensors()
            try processDownloadedSensors(sensors)
            return nil
        }catch{
            return error
        }
    }
    
    func downloadSensorDataFromRemote() -> ErrorType?  {
        do{
            //get Sensors from Local storage
            let sensors = getSensorsInLocal()
            //download sensor data from remote
            for sensor in sensors{
                if sensor.remoteDownloadEnabled {
                    let sensorData = try proxy.getSensorData(sourceName: sensor.source, sensorName: sensor.name)
                    try insertSensorDataIntoLocalDB(sensorData!, sensorId: sensor.id)
                    sensor.remoteDataPointsDownloaded = true
                    try DatabaseHandler.updateSensor(sensor)
                }
            }
            return nil
        } catch {
            return error
        }
    }

    func uploadToRemote() -> ErrorType? {
        let rawSensorList = DatabaseHandler.getSensors(DataSyncer.SOURCE)
        for sensor in rawSensorList {
            uploadSensorDataToRemote(sensor)
        }
        return nil
    }
    
    func cleanUpLocalStorage() -> ErrorType? {
        let rawSensorList = DatabaseHandler.getSensors(DataSyncer.SOURCE)
        for sensor in rawSensorList {
            let persistenceBoundary = NSDate().dateByAddingTimeInterval (0 - persistentPeriod)
            if sensor.remoteUploadEnabled {
                deleteDataPointsLocally(sensor.id, persistLocally: sensor.persistLocally, boundary: persistenceBoundary)
            }
        }
        return nil
    }
    
    // MARK: Helper functions
    
    private func getSensorsInLocal() -> Array<Sensor>{
        var allSensorsInLocal = Array<Sensor>()
        let sources = DatabaseHandler.getSources()
        for source in sources{
            allSensorsInLocal.appendContentsOf(DatabaseHandler.getSensors(source))
        }
        return allSensorsInLocal
    }
    
    private func processDeletionRequests(dataDeletionRequests: [DataDeletionRequest]) throws {
        for request in dataDeletionRequests {
            try proxy.deleteSensorData(sourceName: request.sourceName, sensorName: request.sensorName, startTime: request.startTime, endTime: request.endTime)
            try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
        }
    }
    
    private func  processDownloadedSensors(sensors: Array<AnyObject>?) throws {
        if sensors != nil {
            let sensors = convertAnyObjArrayToSensorArray(sensors)
            try insertSensorsIntoLocalDB(sensors)
            
            // invoke delegates
            for delegate in delegates{
                delegate.onSensorsDownloaded(sensors)
            }
        }
    }
    
    private func convertAnyObjArrayToSensorArray(inputArray: Array<AnyObject>?) -> Array<Sensor>{
        var sensors = Array<Sensor>()
        for anyObj in inputArray! {
            sensors.append(getSensorFromAnyObj(anyObj))
        }
        return sensors
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
    
    private func getSensorFromAnyObj(anyObj: AnyObject) -> Sensor{
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
            let value = dataDict["value"] as! String
            let time = NSDate(timeIntervalSince1970: dataDict["time"] as! Double / 1000)
            let dataPoint = DataPoint(sensorId: sensorId, value: value, time: time)
            //
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }
    }
    
    func deleteDataPointsLocally (id:Int, persistLocally: Bool, boundary:NSDate?)  -> ErrorType?{
        if persistLocally {
            let queryOptions = QueryOptions(startTime: nil, endTime: boundary!, existsInRemote: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
            deleteDataPointsInRLM(id, queryOptions: queryOptions)
        }else{
            let queryOptions = QueryOptions(startTime: nil, endTime: nil, existsInRemote: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
            deleteDataPointsInRLM(id, queryOptions: queryOptions)
        }
        return nil
    }
    
    func deleteDataPointsInRLM(id:Int, queryOptions:QueryOptions) -> ErrorType? {
        do{
            try DatabaseHandler.deleteDataPoints(id, queryOptions)
        }catch{
            return error
        }
        return nil
    }
    
    func uploadSensorDataToRemote(sensor: Sensor) -> ErrorType? {
        if sensor.remoteUploadEnabled {
            let queryOptions = QueryOptions(startTime: nil, endTime: nil, existsInRemote: false, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
            return putSensorDataToRemote(sensor, queryOptions: queryOptions)
        }
        return nil
    }
    
    func putSensorDataToRemote(sensor: Sensor, queryOptions: QueryOptions)-> ErrorType? {
        do{
            let dataPoints = try sensor.getDataPoints(queryOptions)
            var dataArray: Array<AnyObject> = []
            for datapoint in dataPoints {
                let dataObject:Dictionary<String, AnyObject> = ["time": datapoint.time, "value": datapoint.value]
                dataArray.append(dataObject)
            }
            try proxy.putSensorData(sourceName: DataSyncer.SOURCE, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
            for datapoint in dataPoints {
                datapoint.existsInRemote = true
                try DatabaseHandler.insertOrUpdateDataPoint(datapoint)
            }
        }catch{
            return error
        }
        return nil
    }
    
}
