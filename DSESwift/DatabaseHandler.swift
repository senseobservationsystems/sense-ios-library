//
//  DatabaseHandler.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

enum RLMError: ErrorType{
    case ObjectNotFound
    case DuplicatedObjects
    case InvalidLimit
    case StartDateLaterThanEndDate
    case UnauthenticatedAccess
    case CanNotChangePrimaryKey
    case InsertFailed
    case UpdateFailed
    case DeleteFailed
}

/**

DatabaseHandler is a class to wrap around Realm database operation and provide methods that actual public interfaces can use, such as DataStorageEngine, Sensor, Source.
*/
class DatabaseHandler: NSObject{
    
    // MARK: For sensor class
    /**
    * Add a data point. Throw exceptions if it fails to add the data point.
    *
    * @param dataPoint: dataPoint to be added
    */
    class func insertOrUpdateDataPoint(dataPoint:DataPoint) throws {
        // Validate the sensorId
        if (!self.isExistingPrimaryKeyForSensor(dataPoint.sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        // Create data point
        let rlmDataPoint = RLMDataPoint()
        
        let realm = try! Realm()
        realm.beginWrite()
        rlmDataPoint.sensorId = dataPoint.sensorId
        rlmDataPoint.date = dataPoint.date.timeIntervalSince1970
        rlmDataPoint.updateId();
        rlmDataPoint.value = dataPoint.value
        rlmDataPoint.synced = dataPoint.synced
        realm.add(rlmDataPoint, update:true)
        
        do {
            try realm.commitWrite()
        } catch {
            throw RLMError.InsertFailed
        }
    }

    /**
    * Get data points from the sensor with the given sensorId. throws exception when invalid setups are given. eg)startDate>=endDate, limit <= 0
    
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param startDate: NSDate for the startDate of the query. nil for no startDate.
    * @param endDate: NSDate for the endDate of the query. nil for no endDate.
    * @param limit: The maximum number of data points. nil for no limit.
    * @return dataPoints: An array of NSDictionary represents data points.
    */
    class func getDataPoints(sensorId sensorId: Int, startDate: NSDate?, endDate: NSDate?, limit: Int?, sortOrder: SortOrder) throws -> [DataPoint]{
        if (limit != nil && limit <= 0){
            throw RLMError.InvalidLimit
        }
        if(isStartDateLaterThanEndDate(startDate, endDate)){
            throw RLMError.StartDateLaterThanEndDate
        }
        
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (sortOrder == SortOrder.Asc) ? true : false;
        let predicates = self.getPredicateForDataPoint(sensorId: sensorId, startDate: startDate, endDate: endDate)
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("date", ascending: isAscending)
        let end = (limit == nil) ? results.count : min(limit!, results.count)
        for rlmDataPoint in results[Range(start:0, end: end)] {
            let dataPoint = DataPoint(rlmDataPoint: rlmDataPoint)
            dataPoints.append(dataPoint)
        }
        return dataPoints
    }
    
    /**
    * Delete data points based on the arguments. 
    *
    * @param sensorId: String for sensorId
    * @param startDate: NSDate for startDate
    * @param endDate: NSDate for endDate
    */
    class func deleteDataPoints(sensorId: Int, startDate: NSDate?, endDate: NSDate?) throws {
        if(isStartDateLaterThanEndDate(startDate, endDate)){
            throw RLMError.StartDateLaterThanEndDate
        }
        
        let realm = try! Realm()
        let predicates = self.getPredicateForDataPoint(sensorId: sensorId, startDate: startDate, endDate: endDate)
        let results = realm.objects(RLMDataPoint).filter(predicates)
        realm.beginWrite()
        for dataPoint in results {
            realm.delete(dataPoint)
        }
        do {
            try realm.commitWrite()
        } catch {
            throw RLMError.DeleteFailed
        }
    }
    

    
    // MARK: For DataStorageEngine class
    
    /**
    * Update Sensor in database with the info of the given Sensor object. 
    * Throws an exception if it fails to updated. The updatable attributes are only meta, csUploadEnabled, csDownloadEnabled, persistLocally and synced.
    *
    * @param sensor: Sensor object containing the updated info.
    */
    class func update(sensor: Sensor) throws {
        //validate the sensorId
        if (!self.isExistingPrimaryKeyForSensor(sensor.id)){
            throw RLMError.ObjectNotFound
        }
        
        if (sensor.userId != KeychainWrapper.stringForKey(KEYCHAIN_USERID)){
            throw RLMError.UnauthenticatedAccess
        }
        
        let rlmSensor = getSensor(sensor.id)
        //check if the sensorName and source is not changed
        if (self.isPrimaryKeysChangedForSensor(sensor, rlmSensor)){
            throw RLMError.CanNotChangePrimaryKey
        }
        
        // Changes to dataType, userId, sensorName, source will be ignored.
        let realm = try! Realm()
        realm.beginWrite()
        rlmSensor.meta = sensor.meta
        rlmSensor.csUploadEnabled = sensor.csUploadEnabled
        rlmSensor.csDownloadEnabled = sensor.csUploadEnabled
        rlmSensor.persistLocally = sensor.persistLocally
        rlmSensor.synced = sensor.synced
        realm.add(rlmSensor, update: true)

        do {
            try realm.commitWrite()
        } catch {
            throw RLMError.UpdateFailed
        }
    }

    /**
    * Insert a new sensor into database if it does not exist yet. Throw exception if it already exists.
    *
    * @param sensor: Sensor object to be added
    */
    class func insertSensor(sensor:Sensor) throws {
        if (sensor.userId != KeychainWrapper.stringForKey(KEYCHAIN_USERID)){
            throw RLMError.UnauthenticatedAccess
        }
        //TODO: check if the same combination of the sensorname and SourceName exists
        if (isExistingCombinationOfSourceAndSensorName(sensor.source,sensor.name)){
            throw RLMError.DuplicatedObjects
        }
        
        let realm = try! Realm()
        let rlmSensor = RLMSensor()
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
        rlmSensor.synced = sensor.synced
        rlmSensor.updateId()
        realm.add(rlmSensor)
        
        do {
            try realm.commitWrite()
        } catch {
            throw RLMError.InsertFailed
        }
    }
    
    /**
    * Returns a specific sensor with the given name and source.
    *
    * @param source: String for source.
    * @param sensorName: String for sensor name.
    * @return A sensor with the given sensor name and source.
    */
    class func getSensor(source: String, _ sensorName: String) throws -> Sensor {
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let results = realm.objects(RLMSensor).filter(predicates)
        if (results.count < 1){
            throw RLMError.ObjectNotFound
        } else if(results.count > 1){
            throw RLMError.DuplicatedObjects
        }
        
        return Sensor(results.first!)
    }
    
    /**
    * Returns all the sensors connected to the given source.
    *
    * @param source: String for source.
    * @return An array of sensors that belongs to the given source.
    */
    class func getSensors(source: String)->[Sensor]{
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
    * Returns all the sources belongs to the current user
    *
    * @return An array of sources that belongs to the current user.
    */
    class func getSources()->[String]{
        var sources = Set<String>()
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let retrievedSensors = realm.objects(RLMSensor).filter(predicates)
        for rlmSensor in retrievedSensors {
            sources.insert(rlmSensor.source)
        }
        
        return Array(sources)
    }
    
    /**
    * Returns an available id for Sensor.
    *
    * @return An available Id
    */
    class func getNextKeyForSensor() -> Int{
        let lockQueue = dispatch_queue_create("com.sense.lockQueue", nil)
        var newId = 0
        dispatch_sync(lockQueue) {
            let realm = try! Realm()
            let results = realm.objects(RLMSensor).sorted("id")
            if (results.count > 0){
                newId = results.max("id")! + 1
            }
        }
        return newId
    }
    


    // MARK: Helper functions
    /**
    * Returns a compound predicate constructed based on the arguments
    *
    * @param sensorId: Int for sensorId
    * @param startDate: NSDate for startDate
    * @param endDate: NSDate for endDate
    * @return A compound predicate constructed from the arguments.
    */
    private class func getPredicateForDataPoint(sensorId sensorId: Int, startDate: NSDate?, endDate: NSDate?)-> NSPredicate{
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

    /**
    * Returns a sensor with the given id.
    */
    private class func getSensor(id: Int) -> RLMSensor {
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
    private class func isExistingPrimaryKeyForSensor(sensorId: Int) -> Bool {
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
    private class func isExistingCombinationOfSourceAndSensorName(source:String, _ sensorName: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count > 0){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if either of sensor name or source is changed.(Compound primary key)
    */
    private class func isPrimaryKeysChangedForSensor(new: Sensor, _ original:RLMSensor) -> Bool{
        let isNameChanged = (new.name != original.name)
        let isSourceChanged = (new.source != original.source)
        let isUserIdChanged = (new.userId != original.userId)
        return isNameChanged || isSourceChanged || isUserIdChanged
    }
    
    /**
    * Returns true if startDate is later or euqal to endDate.
    */
    private class func isStartDateLaterThanEndDate(startDate: NSDate?, _ endDate: NSDate?) -> Bool {
        return (startDate != nil) && (endDate != nil) && (startDate?.timeIntervalSince1970 >= endDate?.timeIntervalSince1970)
    }
}

