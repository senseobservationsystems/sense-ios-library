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
            rlmDataPoint.setCompoundSensorID(dataPoint.sensorId)
            rlmDataPoint.setCompoundDate(dataPoint.date.timeIntervalSince1970)
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
    func getDataPoints(sensorId sensorId: String, startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: SortOrder) throws -> [DataPoint]{
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
    
    
    // MARK: For source class
    
    /**
    * Update RLMSensor in database with the info of the given Sensor object. Throws an exception if it fails to updated.
    * @param sensor: Sensor object containing the updated info.
    */
    func update(sensor: Sensor) throws {
        //validate the sourceId and sensorId
        if (!self.isExistingPrimaryKeyForSource(sensor.sourceId) || !self.isExistingPrimaryKeyForSensor(sensor.id)){
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
            rlmSensor.sourceId = sensor.sourceId
            rlmSensor.dataType = sensor.dataType
            rlmSensor.csId = sensor.csId //TODO: How should we get Common Sense Sensor id??
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
    * @param sourceId: String for sourceId.
    * @param dataType: String for dataType.
    * @param sensorOptions: DSESensorOptions object.
    */
    func insertSensor(sensor:Sensor) throws {
        //validate the source Id
        if (!self.isExistingPrimaryKeyForSource(sensor.sourceId)){
            throw RLMError.ObjectNotFound
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
            rlmSensor.sourceId = sensor.sourceId
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
    * Update RLMSource in database with the info of the given Source object. Throws an exception if it fails to updated.
    * @param source: Source object containing the updated info.
    */
    func update(source: Source) throws {
        //validate the source Id
        if (!self.isExistingPrimaryKeyForSource(source.id)) {
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        
        do {
            let rlmSource = self.getSource(source.id)
            realm.beginWrite()
            rlmSource.name = source.name
            rlmSource.meta = source.meta
            rlmSource.deviceId = source.deviceId
            rlmSource.csId = source.csId
            realm.add(rlmSource, update:true)
            try realm.commitWrite()
        } catch {
            throw RLMError.UpdateFailed
        }
    }
    
    /**
    * Returns a specific sensor by name connected to the source with the given sourceId.
    *
    * @param sourceId: String for sourceId.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and sourceId.
    */
    func getSensor(sourceId: String, _ sensorName: String) throws -> Sensor {
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND sourceId = %@", sensorName,
            sourceId)
        let results = realm.objects(RLMSensor).filter(predicates)
        if (results.count != 1){
            throw RLMError.ObjectNotFound
        }
        
        return Sensor(results.first!)
    }
    
    /**
    * Returns all the sensors connected to the source with the given sourceId.
    *
    * @param sourceId: String for sensorId.
    * @param sensorName: String for sensor name.
    * @return sensors: An array of sensors that belongs to the source with the given sourceId.
    */
    func getSensors(sourceId: String)->[Sensor]{
        var sensors = [Sensor]()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "sourceId = %@", sourceId)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            let sensor = Sensor(rlmSensor)
            sensors.append(sensor)
        }

        return sensors
    }
    
    // MARK: For DataStorageEngine class
    
    /**
    * Insert a Source Object
    *
    * @param name The name of the source
    * @param deviceId the unique identifier of the source
    */
    func insertSource(source: Source) throws {
        let realm = try! Realm()
    
        let rlmSource = RLMSource()
        do{
            realm.beginWrite()
            rlmSource.id = source.id
            rlmSource.name = source.name
            rlmSource.meta = source.meta
            rlmSource.deviceId = source.deviceId
            rlmSource.userId = source.userId
            rlmSource.csId = source.csId
            realm.add(rlmSource)
            try realm.commitWrite()
        }catch{
            throw RLMError.InsertFailed
        }
    }
    
    /**
    * Returns a list of sources based on the specified criteria.
    *
    * @return list of source objects that correspond to the specified criteria.
    */
    func getSources()-> [Source]{
        var sources  = [Source]()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let results = realm.objects(RLMSource).filter(predicates)
        for rlmSource in results {
            let source = Source(source: rlmSource)
            sources.append(source)
        }
        
        return sources
    }
    
    /**
    * Returns a source based on the source name and source deviceId.
    *
    * @param name The source name, or null to only select based on the deviceId
    * @param deviceId The source deviceId of, or null to only select based on the name
    * @return list of source objects that correspond to the specified criteria.
    */
    func getSource(sourceName: String, _ deviceId: String) throws -> RLMSource{
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND deviceId = %@ AND userId =%@", sourceName, deviceId, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let results = realm.objects(RLMSource).filter(predicates)
        
        if (results.count != 1){
            throw RLMError.ObjectNotFound
        }
        return results.first!
    }
    
    
    // MARK: Helper functions

    /*
    * Returns all the sensor which belong to the current user.
    */
    private func getSensors() -> [RLMSensor] {

        let predicates = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let results = try! Realm().objects(RLMSensor).filter(predicates)
        return Array(results)
    }

    
    private func getSensor(id: String) -> RLMSensor {

        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            sensor = result.first!
        }
        return sensor
    }
    
    private func getSource(id: String) -> RLMSource {
        
        var source = RLMSource()
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSource).filter(predicates)
        if(result.count == 1){
            source = result.first!
        }
        return source
    }
    
    /**
    * Returns true if sensor with the given sensorId exists.
    */
    private func isExistingPrimaryKeyForSensor(sensorId: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "id = %@", sensorId)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if source with the given sourceId exists.
    */
    private func isExistingPrimaryKeyForSource(sourceId: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "id = %@", sourceId) //TODO: use username from the keychain
        let result = try! Realm().objects(RLMSource).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if source with the given sourceId exists.
    */
    private func isExistingPrimaryKeyForDataPoint(primaryKey: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "compoundKey = %@", primaryKey) //TODO: use username from the keychain
        let result = try! Realm().objects(RLMDataPoint).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
}

