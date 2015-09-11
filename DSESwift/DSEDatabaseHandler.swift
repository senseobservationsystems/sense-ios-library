//
//  DatabaseHandler.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

/**
DatabaseHandler is a class to wrap around Realm database operation and provide methods that actual public interfaces can use, such as DataStorageEngine, DSESensor, DSESource.
*/
class DSEDatabaseHandler: NSObject{
    
    /**
    * Add a datapoint to the sensor with the given sensorId.
    
    * @param sensorID: String for the sensorID of the sensor that the datapoint belongs to.
    * @param value: AnyObject for the value.
    * @param date: NSDate for the datetime of the datapoint.
    */
    func addDatapoint(sensorId : String, value: AnyObject, date: NSDate){
        let rlmSensor = RLMSensor()
        rlmSensor.id = sensorId;
        let rlmDatapoint = RLMDatapoint(sensor: rlmSensor, value: 0.0, date: NSDate().timeIntervalSince1970, synced: true);
        do{
            let realm = try! Realm()
            try realm.write {
                realm.add(rlmDatapoint)
            }
        }catch{
            print("error")
        }
    }

    /**
    * Get datapoints from the sensor with the given sensorId.
    
    * @param sensorID: String for the sensorID of the sensor that the datapoint belongs to.
    * @param startDate: NSDate for the startDate of the query.
    * @param endDate: NSDate for the endDate of the query.
    * @param limit: The maximum number of data points.
    * @return datapoints: An array of NSDictionary represents datapoints.
    */
//    func getDatapoints(sensorID: String, startDate: NSDate, endDate: NSDate, limit: Int, sortOrder: String)-> [NSDictionary]{
        //Note for Alex: NSDate should be converted to Double in RealmQuery. They will drop milliseconds automatically
//    }
    
    /**
    * Set the meta data and the options for enabling data upload/download to Common Sense and local data persistence.
    *
    * @param sensorID: String for the sensorID of the sensor that the new setting should be applied to.
    * @param sensorOptions: DSESensorOptions object.
    */
//    func setSensorOptions(sensorID: String, sensorOptions: DSESensorOptions){
//    }
    
    //For source class
    /**
    * Create a new sensor in database if it does not exist yet. Throw exception if it already exists. If it has been created, return the object.
    *
    * @param sensorName: String for sensor name.
    * @param sourceId: String for sourceID.
    * @param dataType: String for dataType.
    * @param sensorOptions: DSESensorOptions object.
    * @return sensor: the sensor that just created.
    */
    func createSensor(sensorName: String, sourceId: String, dataType: String, sensorOptions: DSESensorOptions)->(DSESensor){
        
        let rlmUser = RLMUser()
        rlmUser.username = ""
        
        
        //keychainusername
        let rlmSource = RLMSource()
        rlmSource.id = sourceId
        
        //TODO: figure out how to get cs_id at this point
        let rlmSensor = RLMSensor(id: "", name: sensorName, meta:sensorOptions.meta, cs_upload_enabled: sensorOptions.uploadEnabled, cs_download_enabled: sensorOptions.downloadEnabled, persist_locally: sensorOptions.persist, user: rlmUser, source: rlmSource, data_type: dataType, cs_id: "")
        
        do{
            let realm = try! Realm()
            try realm.write {
                realm.add(rlmSensor)
            }
        }catch{
            print("error")
        }
        
        return DSESensor(sensor: rlmSensor)
    }
    
    /**
    * Returns a specific sensor by name connected to the source with the given sourceID.
    *
    * @param sourceId: String for sourceID.
    * @param sensorName: String for sensor name.
    * @return sensor: sensor with the given sensor name and sourceID.
    */
//    func getSensor(sourceID: String, sensorName: String)->(DSESensor){
//    }
    
    /**
    * Returns all the sensors connected to the source with the given sourceID.
    *
    * @param sourceId: String for sensorID.
    * @param sensorName: String for sensor name.
    * @return sensors: An array of sensors that belongs to the source with the given sourceID.
    */
//    func getSensors(sourceID: String)->[DSESensor]{
//    }
    
    //For DataStorageEngine class
    
    /**
    * Returns a list of sources based on the specified criteria.
    *
    * @param name The source name, or null to only select based on the uuid
    * @param uuid The source uuid of, or null to only select based on the name
    * @return list of source objects that correspond to the specified criteria.
    */
//    func getSources(sourceName: String, uuid: String)-> [DSESource]{
//    }
    
    
}

