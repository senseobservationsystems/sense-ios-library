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
    case DuplicatedObjects
}

enum RLMSortOrder: ErrorType{
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
    func addDataPoint(sensorId sensorId : String, value: AnyObject, date: NSDate) throws {
        //Validate the sensorId
        if (!self.isValidSensorId(sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        // create data point
        let rlmDataPoint = RLMDataPoint()
        rlmDataPoint.sensorId = sensorId
        rlmDataPoint.date = date.timeIntervalSince1970
        rlmDataPoint.value = value
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
    func getDataPoints(sensorId sensorId: String, startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: RLMSortOrder)-> [DataPoint]{
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (sortOrder == RLMSortOrder.Asc) ? true : false;
        let predicates = NSPredicate(format: "sensorId = %@ AND date >= %@ AND date < %@ ", sensorId, startDate.timeIntervalSince1970, endDate.timeIntervalSince1970)
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("date", ascending: isAscending)
        for rlmDataPoint in results {
            let dataPoint = DataPoint(rlmDataPoint: rlmDataPoint)
            dataPoints.append(dataPoint)
        }
        return dataPoints
    }
    
    func updateSensor(sensor: Sensor) {
        
    }
    
    /**
    * Set the meta data and the options for enabling data upload/download to Common Sense and local data persistence.
    *
    * @param sensorId: String for the sensorId of the sensor that the new setting should be applied to.
    * @param sensorOptions: DSESensorOptions object.
    */
    /*
    func setSensorOptions(sensorId: String, _ sensorOptions: SensorOptions) {
        do{
            let realm = try! Realm()
            let sensor = try self.getSensor(sensorId)
            sensor.cs_download_enabled = sensorOptions.downloadEnabled
            sensor.cs_upload_enabled = sensorOptions.uploadEnabled
            sensor.persist_locally = sensorOptions.persist
            sensor.meta = sensorOptions.meta
            try realm.write{
                realm.add(sensor, update: true)
            }
        } catch {
            print("failed to set options for the sensor")
        }
    }
    */
    
    //For Datapoint class
    
    func updateDataPoint(dataPoint: DataPoint) {
        
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
        do {
            rlmSensor.id = rlmSensor.getNextKey()
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
                realm.add(rlmSensor)
            }
        } catch {
            throw RLMError.InsertFailed
        }
    }
    
    func updateSource(source: Source) {
        
    }
    
    /**
    * Returns a specific sensor by name connected to the source with the given sourceId.
    *
    * @param sourceId: String for sourceId.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and sourceId.
    */
    func getSensor(sourceId sourceId: String, _ sensorName: String)->(Sensor){
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "name = %@ AND sourceId = %@", sourceId)
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
    
        //TODO: figure out how to get cs_id at this point
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
    
    private func getSensor(id: String) throws -> RLMSensor {
        if(!self.isValidSensorId(id)){
            throw RLMError.ObjectNotFound
        }
        
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

