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
    let SOURCE: String = "sense-ios"
    static var timer:NSTimer?
    //verify the value and unit
    static var SYNC_RATE = 18000.0
    static var persistPeriod: Double = 2678400000.0

    class func enablePeriodicSync() {
        if timer == nil {
            timer = NSTimer.scheduledTimerWithTimeInterval(SYNC_RATE, target: self, selector: Selector("synchronize"), userInfo: nil, repeats: true);
        }
        timer!.fire()
    }

    class func disablePeriodicSync(){
        timer!.invalidate()
    }
    
    class func initializeSensorProfile(){
        dispatch_promise{
            DataSyncer().downloadSensorProfile()
        }
    }
    
    class func synchronize() throws {
        
        dispatch_promise{
            return DataSyncer().deletionInRemote()
        }.then{ e in
            return DataSyncer().downloadFromRemote()
        }.then{ e in
            return DataSyncer().uploadToRemote()
        }.then{ e in
            return DataSyncer().cleanUpLocalStorage()
        }.catch_ { error in
            //FIXME:what should be included here ?
        }
    }

    func downloadSensorProfile() {
        MockProxy.getSensorProfile()
    }
    
    func deletionInRemote() -> RLMError {
        var error:RLMError?
        let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
        if !dataDeletionRequests.isEmpty {
            for request in dataDeletionRequests {
                MockProxy.deleteSensorData(request.sourceName, sensorName: request.sensorName, startTime: request.startDate, endTime: request.endDate)
                do{
                    try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
                }catch let e as RLMError {
                    error = e
                }
                catch{
                }
            }
        }
         return error!
    }
    
    func downloadFromRemote() -> RLMError {
        var error:RLMError?
        let sensorList = MockProxy.getSensors(SOURCE)
        if !sensorList.isEmpty {
            for sensor in sensorList {
                // FIXME: change the way to pass meta data to the func
                let sensorOptions = SensorOptions(meta: sensor.description, uploadEnabled: false, downloadEnabled: true, persist: false)
                // FIXME: change the way to pass source and sensor name to the func
                if !DatabaseHandler.hasSensor(SOURCE, sensorName: sensor.description) {
                    // FIXME sensor now still has data type 
                    let sensor = Sensor(name: "light", sensorOptions: sensorOptions, userId:KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: SOURCE, dataType: "JSON", csDataPointsDownloaded: false )
                    do{
                        try DatabaseHandler.insertSensor(sensor)
                    }catch let e as RLMError {
                        error = e
                    }
                    catch{
                    }
                }
            }
        }
        let sensorListInLocal = DatabaseHandler.getSensors(SOURCE)
        if !sensorListInLocal.isEmpty {
            for sensor in sensorListInLocal {
                let dataList = MockProxy.getSensorData(SOURCE, sensorName: sensor.name, queryOptions: QueryOptions())
                for dataFromRemote in dataList {
                    // FIXME: need to know the returned data strcture first, and create the data point (there are two insertdatapoint)
                    sensor.insertDataPoint(dataFromRemote.valueForKey("value"), NSDate())
                }
                // FIXME: need to update to Realm！
                sensor.csDataPointsDownloaded = true
            }
        }
        return error!
    }
    
        
    func uploadToRemote() -> RLMError {
        var error:RLMError?
        let rawSensorList = DatabaseHandler.getSensors(SOURCE)
        for sensor in rawSensorList {
            if sensor.csUploadEnabled {
                let queryOption = QueryOptions(startDate: nil, endDate: nil, existsInCS: false, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
                do{
                    let dataPoints = try sensor.getDataPoints(queryOption)
                    // FIXME: using the JSONArray to add datapoint ?
                    let dataArray: NSMutableArray = []
                    for datapoint in dataPoints {
                        let dataObject:Dictionary<String, AnyObject> = ["date": datapoint.date, "value": datapoint.value]
                        dataArray.addObject(dataObject)
                    }
                    MockProxy.putSensorData(SOURCE, sensorName: sensor.name, dataArray: dataArray, meta: sensor.meta)
                    for datapoint in dataPoints {
                        // FIXME: need to update to Realm
                        datapoint.existsInCS = true
                    }
                }catch let e as RLMError {
                    error = e
                }catch{
                }
            }
        }
        return error!
    }
    
    func cleanUpLocalStorage() -> RLMError {
        var error:RLMError?
        let rawSensorList = DatabaseHandler.getSensors(SOURCE)
        for sensor in rawSensorList {
            let persistenceBoundary = NSDate().dateByAddingTimeInterval (0 - DataSyncer.persistPeriod)
            if sensor.csUploadEnabled {
                if sensor.persistLocally {
                    // FIXME:  QueryOptions use NSDate
                    let queryOptions = QueryOptions(startDate: nil, endDate: persistenceBoundary, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
                    do{
                        try DatabaseHandler.deleteDataPoints(sensor.id, queryOptions)
                    }catch let e as RLMError {
                        error = e
                    }
                    catch{
                    }
                }else {
                    let queryOptions = QueryOptions(startDate: nil, endDate: nil, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
                    do{
                        try DatabaseHandler.deleteDataPoints(sensor.id, queryOptions)
                    }catch let e as RLMError {
                        error = e
                    }
                    catch{
                    }
                }
            }
        }
        return error!
    }
    
    
}