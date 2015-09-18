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
    func insertDataPoint(dataPoint:DataPoint) throws {
        //Validate the sensorId
        if (!self.isValidSensorId(dataPoint.sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        // create data point
        let rlmDataPoint = RLMDataPoint()
        rlmDataPoint.sensorId = dataPoint.sensorId
        rlmDataPoint.date = dataPoint.date.timeIntervalSince1970
        rlmDataPoint.value = dataPoint.value
        do{
            let realm = try! Realm()
            try realm.write {
                realm.add(rlmDataPoint)
            }
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
        if (!self.isValidSensorId(sensorId)){
            throw RLMError.ObjectNotFound
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
    
    /**
    * Update RLMSensor in database with the info of the given Sensor object. Throws an exception if it fails to updated.
    * @param sensor: Sensor object containing the updated info.
    */
    func update(sensor: Sensor) throws {
        //validate the sourceId and sensorId
        if (!self.isValidSourceId(sensor.sourceId) || !self.isValidSensorId(sensor.id)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        do {
            let rlmSensor = try getSensor(sensor.id)
            rlmSensor.name = sensor.name
            rlmSensor.meta = sensor.meta
            rlmSensor.cs_upload_enabled = sensor.cs_upload_enabled
            rlmSensor.cs_download_enabled = sensor.cs_upload_enabled
            rlmSensor.persist_locally = sensor.persist_locally
            rlmSensor.userId = sensor.userId
            rlmSensor.sourceId = sensor.sourceId
            rlmSensor.data_type = sensor.data_type
            rlmSensor.cs_id = sensor.cs_id //TODO: How should we get Common Sense Sensor id??
            rlmSensor.synced = sensor.synced
            try realm.write {
                realm.add(rlmSensor, update: true)
            }
        } catch {
            throw RLMError.UpdateFailed
        }
    }
    
    //For Datapoint class
    /**
    * Update RLMDatapoint in database with the info of the given DataPoint object. Throws an exception if it fails to updated.
    * @param dataPoint: DataPoint object containing the updated info.
    */
    func update(dataPoint: DataPoint) throws {
        //validate the source Id
        if (!self.isValidSensorId(dataPoint.sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        do {
            let rlmDataPoint = RLMDataPoint()
            rlmDataPoint.sensorId = dataPoint.sensorId
            rlmDataPoint.date = dataPoint.date.timeIntervalSince1970
            rlmDataPoint.value = dataPoint.value
            try realm.write {
                realm.add(rlmDataPoint, update: true)
            }
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
        if (!self.isValidSourceId(sensor.sourceId)){
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        let rlmSensor = RLMSensor()
        rlmSensor.id = sensor.id
        rlmSensor.name = sensor.name
        rlmSensor.meta = sensor.meta
        rlmSensor.cs_upload_enabled = sensor.cs_upload_enabled
        rlmSensor.cs_download_enabled = sensor.cs_upload_enabled
        rlmSensor.persist_locally = sensor.persist_locally
        rlmSensor.userId = sensor.userId
        rlmSensor.sourceId = sensor.sourceId
        rlmSensor.data_type = sensor.data_type
        rlmSensor.cs_id = sensor.cs_id //TODO: How should we get Common Sense Sensor id??
        rlmSensor.synced = sensor.synced
        
        do {
            try realm.write {
                realm.add(rlmSensor)
            }
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
        if (!self.isValidSourceId(source.id)) {
            throw RLMError.ObjectNotFound
        }
        
        let realm = try! Realm()
        
        do {
            let rlmSource = RLMSource()
            rlmSource.id = source.id
            rlmSource.name = source.name
            rlmSource.meta = source.meta
            rlmSource.uuid = source.uuid
            rlmSource.cs_id = source.cs_id
            
            try realm.write {
                realm.add(rlmSource, update:true)
            }
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
        
        let predicates = NSPredicate(format: "name = %@ AND sourceId = %@", sensorName,
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

        let predicates = NSPredicate(format: "sourceId = %@", sourceId)
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
        rlmSource.id = source.id
        rlmSource.name = source.name
        rlmSource.meta = source.meta
        rlmSource.uuid = source.uuid
        rlmSource.cs_id = source.cs_id
        
        do{
            try realm.write {
                realm.add(rlmSource)
            }
        }catch{
            throw RLMError.InsertFailed
        }
    }
    
    /**
    * Returns a list of sources based on the specified criteria.
    *
    * @param name The source name, or null to only select based on the uuid
    * @param uuid The source uuid of, or null to only select based on the name
    * @return list of source objects that correspond to the specified criteria.
    */
    func getSources(sourceName: String, _ uuid: String)-> [Source]{
        var sources  = [Source]()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND uuid = %@", sourceName, uuid)
        let results = realm.objects(RLMSource).filter(predicates)
        for rlmSource in results {
            let source = Source(source: rlmSource)
            sources.append(source)
        }

        return sources
    }
    
    
    // MARK: Helper functions

    
    private func getSensor(id: String) -> RLMSensor {

        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count==1){
            sensor = result.first!
        }
        return sensor
    }
    
    /**
    * Returns true if sensor with the given sensorId exists.
    */
    private func isValidSensorId(id: String) -> Bool {
        var isValid = false
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            isValid = true
        }
        return isValid
    }
    
    /**
    * Returns true if source with the given sourceId exists.
    */
    private func isValidSourceId(id: String) -> Bool {
        var isValid = false
        let predicates = NSPredicate(format: "id = %@", id) //TODO: use username from the keychain
        let result = try! Realm().objects(RLMSource).filter(predicates)
        if(result.count == 1){
            isValid = true
        }
        return isValid
    }
}

