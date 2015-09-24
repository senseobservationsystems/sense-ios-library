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
    case UnauthenticatedAccess
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
    func getDataPoints(sensorId sensorId: Int, startDate: NSDate?, endDate: NSDate?, limit: Int, sortOrder: SortOrder) throws -> [DataPoint]{
        if (limit < -1 || limit == 0){
            throw RLMError.InvalidLimit
        }
        
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (sortOrder == SortOrder.Asc) ? true : false;
        let predicates = self.getPredicateForDataPoint(sensorId: sensorId, startDate: startDate, endDate: endDate)
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("date", ascending: isAscending)
        let end = (limit == -1) ? results.count : min(limit,results.count)
        for rlmDataPoint in results[Range(start:0, end: end)] {
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
        
        if (sensor.userId != KeychainWrapper.stringForKey(KEYCHAIN_USERID)){
            throw RLMError.UnauthenticatedAccess
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
        if (sensor.userId != KeychainWrapper.stringForKey(KEYCHAIN_USERID)){
            throw RLMError.UnauthenticatedAccess
        }
        //TODO: check if the same combination of the sensorname and SourceName exists
        if (isExistingCombinationOfSourceAndSensorName(sensor.source,sensor.name)){
            throw RLMError.DuplicatedObjects
        }
        
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
    * Returns a specific sensor by name connected to the source with the given sensorName.
    *
    * @param source: String for source.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and source.
    */
    func getSensor(source: String, _ sensorName: String) throws -> Sensor? {
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let results = realm.objects(RLMSensor).filter(predicates)
        
        return (results.count<1) ? nil : Sensor(results.first!)
    }
    
    /**
    * Returns all the sensors connected to the given source.
    *
    * @param source: String for sensorId.
    * @return sensors: An array of sensors that belongs to the source with the given source.
    */
    func getSensors(source: String)->[Sensor]{
        var sensors = [Sensor]()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "source = %@ AND userId = %@", source, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            let sensor = Sensor(rlmSensor)
            sensors.append(sensor)
        }

        return sensors
    }
    
    /**
    * Returns all the sensors connected to the given source.
    *
    * @param source: String for sensorId.
    * @return sensors: An array of sensors that belongs to the source with the given source.
    */
    func getSources()->[String]{
        var sources = Set<String>()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            sources.insert(rlmSensor.source)
        }
        
        return Array(sources)
    }
    

    // MARK: Helper functions
    private func getPredicateForDataPoint(sensorId sensorId: Int, startDate: NSDate?, endDate: NSDate?)-> NSPredicate{
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "sensorId = %d", sensorId))
        if(startDate != nil){
            predicates.append(NSPredicate(format: "date >= %f", startDate!.timeIntervalSince1970))
        }
        if(endDate != nil){
            predicates.append(NSPredicate(format: "date < %f" , endDate!.timeIntervalSince1970))
        }
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
    }

    
    private func getSensor(id: Int) -> RLMSensor {
        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %d AND userId = %@", id, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
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
        let predicates = NSPredicate(format: "id = %d AND userId = %@", sensorId, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if source with the combination of the given source and sensor exists.
    */
    private func isExistingCombinationOfSourceAndSensorName(source:String, _ sensorName: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count > 0){
            exists = true
        }
        return exists
    }
}

