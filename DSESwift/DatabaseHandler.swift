//
//  DatabaseHandler.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

//TODO: let's make this more explicit
enum RLMError: ErrorType{
    case ObjectNotFound
    case InsertFailed
    case UpdateFailed
    case DuplicatedObjects
    case InvalidLimit
}

enum SortOrder: ErrorType{
    case Asc
    case Desc
}

/**
TODO: Make Static!

DatabaseHandler is a class to wrap around Realm database operation and provide methods that actual public interfaces can use, such as DataStorageEngine, Sensor, Source.
*/
class DatabaseHandler: NSObject{
    
    
    // MARK: For sensor class
    /**
    * Add a data point to the sensor with the given sensorId. Throw exceptions if it fails to add the data point.
    
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param value: AnyObject for the value.
    * @param date: NSDate for the datetime of the data point.
    */
    func insertOrUpdateDataPoint(dataPoint:DataPoint) throws {
        //Validate the sensorId
        if (!self.isExistingPrimaryKeyForSensor(dataPoint.sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        // create data point
        let rlmDataPoint = RLMDataPoint()
        do {
            let realm = try! Realm()
            realm.beginWrite()
            rlmDataPoint.sensorId = dataPoint.sensorId
            rlmDataPoint.date = dataPoint.date.timeIntervalSince1970
            rlmDataPoint.updateId();
            rlmDataPoint.value = dataPoint.value
            realm.add(rlmDataPoint, update:true)
            try realm.commitWrite()
        } catch {
            throw RLMError.InsertFailed
        }
    }

    /**
    * Get data points from the sensor with the given sensorId.
    
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param startDate: NSDate for the startDate of the query.
    * @param endDate: NSDate for the endDate of the query.
    * @param limit: The maximum number of data points.
    * @return dataPoints: An array of NSDictionary represents data points.
    */
    func getDataPoints(sensorId sensorId: Int, startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: SortOrder) throws -> [DataPoint]{
        if (!self.isExistingPrimaryKeyForSensor(sensorId)){
            throw RLMError.ObjectNotFound
        }
        if (limit < 1){
            throw RLMError.InvalidLimit
        }
        
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (sortOrder == SortOrder.Asc) ? true : false;
        let predicates = NSPredicate(format: "sensorId = %@ AND date >= %f AND date < %f", sensorId, startDate.timeIntervalSince1970, endDate.timeIntervalSince1970) //
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("date", ascending: isAscending)
        for rlmDataPoint in results {
            let dataPoint = DataPoint(rlmDataPoint: rlmDataPoint)
            dataPoints.append(dataPoint)
        }
        return dataPoints
    }
    
    
    // MARK: For DataStorageEngine class
    
    /**
    * Update RLMSensor in database with the info of the given Sensor object. Throws an exception if it fails to updated.
    * @param sensor: Sensor object containing the updated info.
    */
    func update(sensor: Sensor) throws {
        //validate the source and sensorId
        if (!self.isExistingPrimaryKeyForSensor(sensor.id)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        do {
            let rlmSensor = getSensor(sensor.id)
            realm.beginWrite()
            rlmSensor.name = sensor.name
            rlmSensor.meta = sensor.meta
            rlmSensor.csUploadEnabled = sensor.csUploadEnabled
            rlmSensor.csDownloadEnabled = sensor.csUploadEnabled
            rlmSensor.persistLocally = sensor.persistLocally
            rlmSensor.userId = sensor.userId
            rlmSensor.source = sensor.source
            rlmSensor.dataType = sensor.dataType
            rlmSensor.csId = sensor.csId 
            rlmSensor.synced = sensor.synced
    
            realm.add(rlmSensor, update: true)
            try realm.commitWrite()
        } catch {
            throw RLMError.UpdateFailed
        }
        
    }

    /**
    * Insert a new sensor into database if it does not exist yet. Throw exception if it already exists. If it has been created, return the object.
    *
    * @param sensorName: String for sensor name.
    * @param source: String for source.
    * @param dataType: String for dataType.
    * @param sensorOptions: DSESensorOptions object.
    */
    func insertSensor(sensor:Sensor) throws {
        let realm = try! Realm()
        let rlmSensor = RLMSensor()
        
        do {
            realm.beginWrite()
            rlmSensor.id = sensor.id
            rlmSensor.name = sensor.name
            rlmSensor.meta = sensor.meta
            rlmSensor.csUploadEnabled = sensor.csUploadEnabled
            rlmSensor.csDownloadEnabled = sensor.csUploadEnabled
            rlmSensor.persistLocally = sensor.persistLocally
            rlmSensor.userId = sensor.userId
            rlmSensor.source = sensor.source
            rlmSensor.dataType = sensor.dataType
            rlmSensor.csId = sensor.csId //TODO: How should we get Common Sense Sensor id??
            rlmSensor.synced = sensor.synced
                
            realm.add(rlmSensor)
            try realm.commitWrite()
        } catch {
            throw RLMError.InsertFailed
        }
    }
    
    /**
    * Returns a specific sensor by name connected to the source with the given source.
    *
    * @param source: String for source.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and source.
    */
    func getSensor(sensorName: String) throws -> Sensor {
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@", sensorName)
        let results = realm.objects(RLMSensor).filter(predicates)
        if (results.count != 1){
            throw RLMError.ObjectNotFound
        }
        
        return Sensor(results.first!)
    }
    
    /**
    * Returns all the sensors connected to the source with the given source.
    *
    * @param source: String for sensorId.
    * @param sensorName: String for sensor name.
    * @return sensors: An array of sensors that belongs to the source with the given source.
    */
    func getSensors()->[Sensor]{
        var sensors = [Sensor]()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            let sensor = Sensor(rlmSensor)
            sensors.append(sensor)
        }

        return sensors
    }
    

    // MARK: Helper functions

    
    private func getSensor(id: Int) -> RLMSensor {
        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            sensor = result.first!
        }
        return sensor
    }
    
    /**
    * Returns true if sensor with the given sensorId exists.
    */
    private func isExistingPrimaryKeyForSensor(sensorId: Int) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "id = %@ AND userId = %@", sensorId, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if source with the given source exists.
    */
    private func isExistingPrimaryKeyForDataPoint(id: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMDataPoint).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
}

