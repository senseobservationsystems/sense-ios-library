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
    static let SOURCE: String = "sense-ios"
    var proxy:SensorDataProxy
    var timer:NSTimer?
    // 30 mins in secs
    static var SYNC_RATE = 18000.0
    // 31 days in secs
    var persistPeriod: Double = 2678400.0

    init (proxy:SensorDataProxy, persistPeriod:Double?) {
        self.proxy = proxy
        if persistPeriod != nil {
            self.persistPeriod = persistPeriod!
        }
    }
    
    func enablePeriodicSync() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(DataSyncer.SYNC_RATE, target: self, selector: Selector("synchronize"), userInfo: nil, repeats: true);
        }
        timer!.fire()
    }

    func disablePeriodicSync(){
        timer!.invalidate()
    }
    
    func initializeSensorProfile(){
        dispatch_promise{
            // FIXME: don't need to return ?
            self.downloadSensorProfile
        }
    }
    
    func synchronize() throws {
        dispatch_promise{
            return self.deletionInRemote
        }.then{ e in
            return self.downloadFromRemote
        }.then{ e in
            return self.uploadToRemote
        }.then{ e in
            return self.cleanUpLocalStorage
        }.catch_ { error in
            //FIXME:what should be included here ?
        }
    }

    func downloadSensorProfile() -> ErrorType? {
        do{
            try proxy.getSensorProfiles()
        }catch{
            return error
        }
        return nil
    }
    
    func deletionInRemote() -> ErrorType? {
        let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
        if !dataDeletionRequests.isEmpty {
            deleteSensorDataInRemote(dataDeletionRequests)
        }
        return nil
    }
    
    func downloadFromRemote() -> ErrorType?  {
        var sensorList: Array<AnyObject>?
        do{
            sensorList = try proxy.getSensors(DataSyncer.SOURCE)
        }catch{
          return error
        }
        if sensorList != nil {
            downloadSensorFromRemote(sensorList!)
        }
        let sensorListInLocal = DatabaseHandler.getSensors(DataSyncer.SOURCE)
        if !sensorListInLocal.isEmpty {
            insertSensorDataLocally(sensorListInLocal)
        }
        return nil
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
            let persistenceBoundary = NSDate().dateByAddingTimeInterval (0 - persistPeriod)
            if sensor.csUploadEnabled {
                deleteDataPointsLocally(sensor.id, persistLocally: sensor.persistLocally, boundary: persistenceBoundary)
            }
        }
        return nil
    }
    
    // MARK: Helper functions
    
    func deleteSensorDataInRemote(dataDeletionRequests: [DataDeletionRequest]) -> ErrorType? {
        for request in dataDeletionRequests {
            do{
                try proxy.deleteSensorData(sourceName: request.sourceName, sensorName: request.sensorName, startDate: request.startDate, endDate: request.endDate)
                try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
            }catch {
                return error
            }
        }
        return nil
    }
    
    func  downloadSensorFromRemote( sensorList: Array<AnyObject>) -> ErrorType? {
        for sensor in sensorList {
            let sensorDict = sensor as! Dictionary<String, AnyObject>
            let metaDict = sensorDict["meta"] as! Dictionary<String, AnyObject>
            let sourceNameInString = sensorDict["source_name"] as! String
            let sensorNameInString = sensorDict["sensor_name"] as! String
            let sensorOptions = SensorOptions(meta: metaDict, uploadEnabled: false, downloadEnabled: true, persist: false)
            if !DatabaseHandler.hasSensor(sourceNameInString, sensorName: sensorNameInString) {
                // FIXME sensor now still has data type
                let sensor = Sensor(name: "light", sensorOptions: sensorOptions, userId:KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: DataSyncer.SOURCE, dataType: "JSON",csDataPointsDownloaded: false )
                do{
                    try DatabaseHandler.insertSensor(sensor)
                }catch{
                    return error
                }
            }
        }
        return nil
    }
    
    func insertSensorDataLocally(sensorListInLocal:[Sensor]) -> ErrorType? {
        for sensor in sensorListInLocal {
            do{
                let dataList = try proxy.getSensorData(sourceName: DataSyncer.SOURCE, sensorName: sensor.name, queryOptions: QueryOptions())
                insertDataPoints(sensor, dataList: dataList)
                sensor.csDataPointsDownloaded = true
                try DatabaseHandler.update(sensor)
            }catch{
                return error
            }
        }
        return nil
    }
    
    func insertDataPoints(sensor: Sensor, dataList: Dictionary<String, AnyObject>?) {
        if dataList != nil{
            for (value, date) in dataList!{
                sensor.insertDataPoint(value, date as! NSDate)
            }
        }
    }
    
    func deleteDataPointsLocally (id:Int, persistLocally: Bool, boundary:NSDate?)  -> ErrorType?{
        if persistLocally {
            let queryOptions = QueryOptions(startDate: nil, endDate: boundary!, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
            deleteDataPointsInRLM(id, queryOptions: queryOptions)
        }else{
            let queryOptions = QueryOptions(startDate: nil, endDate: nil, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
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
        if sensor.csUploadEnabled {
            let queryOptions = QueryOptions(startDate: nil, endDate: nil, existsInCS: false, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
            return putSensorDataToRemote(sensor, queryOptions: queryOptions)
        }
        return nil
    }
    
    func putSensorDataToRemote(sensor: Sensor, queryOptions: QueryOptions)-> ErrorType? {
        do{
            let dataPoints = try sensor.getDataPoints(queryOptions)
            var dataArray: Array<AnyObject> = []
            for datapoint in dataPoints {
                let dataObject:Dictionary<String, AnyObject> = ["date": datapoint.date, "value": datapoint.value]
                dataArray.append(dataObject)
            }
            try proxy.putSensorData(sourceName: DataSyncer.SOURCE, sensorName: sensor.name, data: dataArray, meta: sensor.meta)
            for datapoint in dataPoints {
                datapoint.existsInCS = true
                try DatabaseHandler.insertOrUpdateDataPoint(datapoint)
            }
        }catch{
            return error
        }
        return nil
    }
    
}