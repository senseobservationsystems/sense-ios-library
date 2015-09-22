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
}

enum SortOrder: ErrorType{
    case Asc
    case Desc
}

/**
DatabaseHandler is a class to wrap around Realm database operation and provide methods that actual public interfaces can use, such as DataStorageEngine, Sensor, Source.
*/
class DatabaseHandler: NSObject{
    
    
    //For sensor class
    /**
    * Add a data point to the sensor with the given sensorId. Throw exceptions if it fails to add the data point.
    
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param value: AnyObject for the value.
    * @param date: NSDate for the datetime of the data point.
    */
    func insertOrUpdateDataPoint(dataPoint:DataPoint) throws {
        //Validate the sensorId
        if (!self.isExistingPrimaryKeyForSensor(dataPoint.sensor_id)){
            throw RLMError.ObjectNotFound
        }
        
        // create data point
        let rlmDataPoint = RLMDataPoint()
        do {
            let realm = try! Realm()
            realm.beginWrite()
            rlmDataPoint.setCompoundSensorID(dataPoint.sensor_id)
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
        
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (sortOrder == SortOrder.Asc) ? true : false;
        let predicates = NSPredicate(format: "sensor_id = %@ AND date >= %f AND date < %f", sensorId, startDate.timeIntervalSince1970, endDate.timeIntervalSince1970) //
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("date", ascending: isAscending)
        for rlmDataPoint in results {
            let dataPoint = DataPoint(rlmDataPoint: rlmDataPoint)
            dataPoints.append(dataPoint)
        }
        return dataPoints
    }
    
    /**
    * Update RLMSensor in database with the info of the given Sensor object. Throws an exception if it fails to updated.
    * @param sensor: Sensor object containing the updated info.
    */
    func update(sensor: Sensor) throws {
        //validate the sourceId and sensorId
        if (!self.isExistingPrimaryKeyForSource(sensor.source_id) || !self.isExistingPrimaryKeyForSensor(sensor.id)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        do {
            let rlmSensor = getSensor(sensor.id)
            realm.beginWrite()
            rlmSensor.name = sensor.name
            rlmSensor.meta = sensor.meta
            rlmSensor.cs_upload_enabled = sensor.cs_upload_enabled
            rlmSensor.cs_download_enabled = sensor.cs_upload_enabled
            rlmSensor.persist_locally = sensor.persist_locally
            rlmSensor.user_id = sensor.user_id
            rlmSensor.source_id = sensor.source_id
            rlmSensor.data_type = sensor.data_type
            rlmSensor.cs_id = sensor.cs_id //TODO: How should we get Common Sense Sensor id??
            rlmSensor.synced = sensor.synced
    
            realm.add(rlmSensor, update: true)
            try realm.commitWrite()
        } catch {
            throw RLMError.UpdateFailed
        }
        
    }
    
    //For source class
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
        if (!self.isExistingPrimaryKeyForSource(sensor.source_id)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        let rlmSensor = RLMSensor()
        
        do {
            realm.beginWrite()
            rlmSensor.id = sensor.id
            rlmSensor.name = sensor.name
            rlmSensor.meta = sensor.meta
            rlmSensor.cs_upload_enabled = sensor.cs_upload_enabled
            rlmSensor.cs_download_enabled = sensor.cs_upload_enabled
            rlmSensor.persist_locally = sensor.persist_locally
            rlmSensor.user_id = sensor.user_id
            rlmSensor.source_id = sensor.source_id
            rlmSensor.data_type = sensor.data_type
            rlmSensor.cs_id = sensor.cs_id //TODO: How should we get Common Sense Sensor id??
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
            rlmSource.uuid = source.uuid
            rlmSource.cs_id = source.cs_id
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
    func getSensor(sourceId: String, _ sensorName: String)->(Sensor){
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND source_id = %@", sensorName,
            sourceId)
        let result = realm.objects(RLMSensor).filter(predicates)
        
        return Sensor(sensor: result.first!)
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
        
        let predicates = NSPredicate(format: "source_id = %@", sourceId)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            let sensor = Sensor(sensor: rlmSensor)
            sensors.append(sensor)
        }

        return sensors
    }
    
    //For DataStorageEngine class
    
    /**
    * Insert a Source Object
    *
    * @param name The name of the source
    * @param uuid the unique identifier of the source
    */
    func insertSource(source: Source) throws {
        let realm = try! Realm()
    
        let rlmSource = RLMSource()
        do{
            realm.beginWrite()
            rlmSource.id = source.id
            rlmSource.name = source.name
            rlmSource.meta = source.meta
            rlmSource.uuid = source.uuid
            rlmSource.cs_id = source.cs_id
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
        
        //TODO: change this method to use user_id on source
        
        //get all the sensors with the user id
        let sensors = getSensors()
        // creat an array of sourceIds from the sensors
        var sourceIds = [String]()
        for sensor in sensors{
            sourceIds.append(sensor.source_id)
        }
        
        let predicates = NSPredicate(format: "id in %@", sourceIds)
        let results = realm.objects(RLMSource).filter(predicates)
        for rlmSource in results {
            let source = Source(source: rlmSource)
            sources.append(source)
        }
        
        return sources
    }
    
    /**
    * Returns a source based on the source name and source uuid.
    *
    * @param name The source name, or null to only select based on the uuid
    * @param uuid The source uuid of, or null to only select based on the name
    * @return list of source objects that correspond to the specified criteria.
    */
    func getSource(sourceName: String, _ uuid: String) throws -> RLMSource{
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND uuid = %@", sourceName, uuid)
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

        let predicates = NSPredicate(format: "user_id = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
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

