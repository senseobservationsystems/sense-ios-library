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
    var persistPeriod: Double = -2678400000.0

    //    func enablePeriodicSync() {}
    //    func disablePeriodicSync(){}
    
    class func initializeSensorProfile(){
        dispatch_promise{
            DataSyncer().downloadSensorProfile()
        }
    }
    
    class func synchronize() throws {
        
        dispatch_promise{
            DataSyncer().deletionInRemote()
        }.then{
            DataSyncer().downloadFromRemote()
        }.then{
            DataSyncer().uploadToRemote()
        }.then{
            DataSyncer().cleanUpLocalStorage()
        }.error{ error in
            print( error )
        }
    }

    func downloadSensorProfile() {
        MockProxy.getSensorProfile()
    }
    
    func deletionInRemote() {
        let dataDeletionRequests = DatabaseHandler.getDataDeletionRequest()
        if !dataDeletionRequests.isEmpty {
            for request in dataDeletionRequests {
                MockProxy.deleteSensorData(request.sourceName, sensorName: request.sensorName, startTime: request.startDate, endTime: request.endDate)
                do{
                    try DatabaseHandler.deleteDataDeletionRequest(request.uuid)
                }catch{
                print("need to fix it")
                }
            }
        }
    }
    
    func downloadFromRemote() {
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
                    }catch{
                        print("need to fix it")
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
    }
    
    func uploadToRemote() {
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
                }catch{
                    print("need to fix it")
                }
            }
        }
    }
    
    func cleanUpLocalStorage() {
        let rawSensorList = DatabaseHandler.getSensors(SOURCE)
        for sensor in rawSensorList {
            let persistenceBoundary = NSDate().dateByAddingTimeInterval (persistPeriod)
            if sensor.csUploadEnabled {
                if sensor.persistLocally {
                    // FIXME: do not need to have requiresDeletionInCS, QueryOptions use NSDate
                    let queryOptions = QueryOptions(startDate: nil, endDate: persistenceBoundary, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
                    do{
                        try DatabaseHandler.deleteDataPoints(sensor.id, queryOptions)
                    }catch{
                        print("need to fix it")
                    }
                }else {
                    let queryOptions = QueryOptions(startDate: nil, endDate: nil, existsInCS: true, limit: nil, sortOrder: SortOrder.Asc, interval: nil)
                    do{
                        try DatabaseHandler.deleteDataPoints(sensor.id, queryOptions)
                    }catch{
                        print("need to fix it")
                    }
                }
            }
        }
    }
    
    
}