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
class DSEDatabaseHandler: NSObject{
    
    /**
    * Add a data point to the sensor with the given sensorId. Throw exceptions if it fails to add the data point.
    
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param value: AnyObject for the value.
    * @param date: NSDate for the datetime of the data point.
    */
    func addDataPoint(sensorId : String, value: AnyObject, date: NSDate) throws {
        do{
            // Make sure that the sensor with the given sensorId exists
            let sensor = try getSensor(sensorId)
            // create data point
            let rlmDataPoint = RLMDataPoint()
            rlmDataPoint.sensorId = sensor.id
            rlmDataPoint.date = date.timeIntervalSince1970
            rlmDataPoint.value = value
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
    func getDataPoints(sensorId: String, startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: RLMSortOrder)-> [DataPoint]{
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
    
    /**
    * Set the meta data and the options for enabling data upload/download to Common Sense and local data persistence.
    *
    * @param sensorId: String for the sensorId of the sensor that the new setting should be applied to.
    * @param sensorOptions: DSESensorOptions object.
    */
    func setSensorOptions(sensorId: String, sensorOptions: SensorOptions) {
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
    
    //For source class
    /**
    * Create a new sensor in database if it does not exist yet. Throw exception if it already exists. If it has been created, return the object.
    *
    * @param sensorName: String for sensor name.
    * @param sourceId: String for sourceId.
    * @param dataType: String for dataType.
    * @param sensorOptions: DSESensorOptions object.
    * @return sensor: the sensor that just created.
    */
    func createSensor(sensor:Sensor)throws ->(Sensor){
        
        //TODO: check if Source with the give sourceId  already exists
        
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
        } catch RLMError.ObjectNotFound {
            //TODO: do something proper
            throw RLMError.InsertFailed
        } catch {
            throw RLMError.InsertFailed
        }
        
        return Sensor(sensor: rlmSensor)
    }
    
    /**
    * Returns a specific sensor by name connected to the source with the given sourceId.
    *
    * @param sourceId: String for sourceId.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and sourceId.
    */
   func getSensor(sourceId: String, sensorName: String)->(Sensor){
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
    * Create a sourceObject and return the created source object
    *
    * @param name The name of the source
    * @param uuid the unique identifier of the source
    * @return list of source objects that correspond to the specified criteria.
    */
    func createSources(sourceName: String, meta: String, uuid: String)-> Source{
        let realm = try! Realm()
    
        //TODO: figure out how to get cs_id at this point
        let rlmSource = RLMSource()
        rlmSource.id = rlmSource.getNextKey()
        rlmSource.name = sourceName
        rlmSource.meta = meta
        rlmSource.uuid = uuid
        rlmSource.cs_id = ""
        
        do{
            try realm.write {
                realm.add(rlmSource)
            }
        }catch{
            //TODO: do something proper
            print("error")
        }
        
        return Source(source: rlmSource)
    }
    
    /**
    * Returns a list of sources based on the specified criteria.
    *
    * @param name The source name, or null to only select based on the uuid
    * @param uuid The source uuid of, or null to only select based on the name
    * @return list of source objects that correspond to the specified criteria.
    */
    func getSources(sourceName: String, uuid: String)-> [Source]{
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
    
    /**
    * Returns the RLMSource object with the given id. Returns the existing object, if RLMSource object with the same id already exists. Throw an exception, if it does not exist in the local storage.
    */
    private func getSensor(id: String) throws -> RLMSensor {
        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %@", id)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count==1){
            sensor = result.first!
        } else if (result.count==0){
            throw RLMError.ObjectNotFound
        } else {
            //This should never happen
            throw RLMError.DuplicatedObjects
        }
        return sensor
    }

    private func getSource(id: String) throws-> RLMSource {
        var source = RLMSource()
        let predicates = NSPredicate(format: "id = %@", id) //TODO: use username from the keychain
        let result = try! Realm().objects(RLMSource).filter(predicates)
        if(result.count==1){
            source = result.first!
        } else if (result.count==0){
            throw RLMError.ObjectNotFound
        } else {
            //This should never happen
            throw RLMError.DuplicatedObjects
        }
            
        return source
    }

}

