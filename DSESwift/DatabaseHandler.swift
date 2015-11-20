//
//  DatabaseHandler.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift
import SwiftyJSON



public enum RLMError: ErrorType{
    case ObjectNotFound
    case DuplicatedObjects
    case InvalidLimit
    case StartTimeLaterThanEndTime
    case UnauthenticatedAccess
    case CanNotChangePrimaryKey
    case InvalidSensorName
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
    static func insertOrUpdateDataPoint(dataPoint:DataPoint) throws {
        // Validate the sensorId
        if (!self.isExistingPrimaryKeyForSensor(dataPoint.sensorId)){
            throw RLMError.ObjectNotFound
        }
        
        // Create data point
        let rlmDataPoint = RLMDataPoint()
        
        let realm = try! Realm()
        realm.beginWrite()
        rlmDataPoint.sensorId = dataPoint.sensorId
        rlmDataPoint.time = dataPoint.time.timeIntervalSince1970
        rlmDataPoint.updateId();
        rlmDataPoint.value = dataPoint.value
        rlmDataPoint.existsInRemote = dataPoint.existsInRemote
        realm.add(rlmDataPoint, update:true)
        
        try realm.commitWrite()
    }

    /**
    * Get data points from the sensor with the given sensorId. throws exception when invalid setups are given. eg)startTime>=endTime, limit <= 0
    * @param sensorId: String for the sensorId of the sensor that the data point belongs to.
    * @param startTime: NSDate for the startTime of the query. nil for no startTime.
    * @param endTime: NSDate for the endTime of the query. nil for no endTime.
    * @param limit: The maximum number of data points. nil for no limit.
    * @return dataPoints: An array of NSDictionary represents data points.
    */
    static func getDataPoints(sensorId: Int,_ queryOptions: QueryOptions) throws -> [DataPoint]{
        if (queryOptions.limit != nil && queryOptions.limit <= 0){
            throw RLMError.InvalidLimit
        }
        if(isStartTimeLaterThanEndTime(queryOptions.startTime, queryOptions.endTime)){
            throw RLMError.StartTimeLaterThanEndTime
        }
        
        var dataPoints = [DataPoint]()
        let realm = try! Realm()
        let isAscending = (queryOptions.sortOrder == SortOrder.Asc) ? true : false;
        let predicates = self.getPredicateForDataPoint(sensorId, queryOptions)
        //query
        let results = realm.objects(RLMDataPoint).filter(predicates).sorted("time", ascending: isAscending)
        let end = (queryOptions.limit == nil) ? results.count : min(queryOptions.limit!, results.count)
        for rlmDataPoint in results[Range(start:0, end: end)] {
            let dataPoint = DataPoint(rlmDataPoint: rlmDataPoint)
            dataPoints.append(dataPoint)
        }
        return dataPoints
    }
    
    /**
    * Delete data points that matches with the given arguments from LocalStorage.
    *
    * @param sensorId: String for sensorId
    * @param queryOptions: queryOptions for deleting criteria
    */
    static func deleteDataPoints(sensorId: Int, _ queryOptions: QueryOptions) throws {
        if(isStartTimeLaterThanEndTime(queryOptions.startTime, queryOptions.endTime)){
            throw RLMError.StartTimeLaterThanEndTime
        }
        
        let realm = try! Realm()
        let predicates = self.getPredicateForDataPoint(sensorId, queryOptions)
        let results = realm.objects(RLMDataPoint).filter(predicates)
        realm.beginWrite()
        for dataPoint in results {
            realm.delete(dataPoint)
        }
        
        try realm.commitWrite()
    }

    /**
    * Store the content of deletion request for data points in the local storage
    * @param sensorName the name of the sensor
    * @param sourceName the source name of the sensor
    * @param startTime the start Time to delete the data points
    * @param endTime the end Time to delete the data points
    */
    static func createDataDeletionRequest(sourceName sourceName: String, sensorName: String, startTime: NSDate?, endTime: NSDate?) throws{
        let realm = try! Realm()
        // Create data deletionrequest
        let rlmDataDeletionRequest = DataDeletionRequest()
        rlmDataDeletionRequest.uuid = NSUUID().UUIDString
        rlmDataDeletionRequest.userId = self.getUserId()
        rlmDataDeletionRequest.sensorName = sensorName
        rlmDataDeletionRequest.sourceName = sourceName
        rlmDataDeletionRequest.startTime = startTime
        rlmDataDeletionRequest.endTime = endTime

        realm.beginWrite()
        realm.add(rlmDataDeletionRequest)
        
        try realm.commitWrite()
    }
    
    /**
    * Get the list of data deletion requests from local storage
    * @return An array of NSDictionary represents data deletion requests
    */
    static func getDataDeletionRequests() -> [DataDeletionRequest] {
        var dataDeletionRequest = [DataDeletionRequest]()
        let realm = try! Realm()
        let predicate = NSPredicate(format: "userId = %@", self.getUserId())
        let results = realm.objects(DataDeletionRequest).filter(predicate)
        for request in results {
            dataDeletionRequest.append(request)
        }
        return dataDeletionRequest
    }
    
    /**
    * Delete the DataDeletionRequest from local storage by querying uuid.
    * @param uuid
    */
    static func deleteDataDeletionRequest(uuid: String) throws {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "uuid = %@ AND userId = %@", uuid, self.getUserId())
        let results = realm.objects(DataDeletionRequest).filter(predicate)
        realm.beginWrite()
        realm.delete(results)
        
        try realm.commitWrite()
    }
    
    
    // MARK: For DataStorageEngine class
    
    /**
    * Update Sensor in database with the info of the given Sensor object. 
    * Throws an exception if it fails to updated. The updatable attributes are only meta, remoteUploadEnabled, remoteDownloadEnabled, persistLocally and synced.
    *
    * @param sensor: Sensor object containing the updated info.
    */
    static func updateSensor(sensor: Sensor) throws {
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
        rlmSensor.meta = JSONUtils.stringify(sensor.meta)
        rlmSensor.remoteUploadEnabled = sensor.remoteUploadEnabled
        rlmSensor.remoteDownloadEnabled = sensor.remoteDownloadEnabled
        rlmSensor.persistLocally = sensor.persistLocally
        rlmSensor.remoteDataPointsDownloaded = sensor.remoteDataPointsDownloaded
        realm.add(rlmSensor, update: true)

        try realm.commitWrite()
    }

    /**
    * Insert a new sensor into database if it does not exist yet. Throw exception if it already exists.
    *
    * @param sensor: Sensor object to be added
    */
    static func insertSensor(sensor:Sensor) throws {
        if (sensor.userId != KeychainWrapper.stringForKey(KEYCHAIN_USERID)){
            throw RLMError.UnauthenticatedAccess
        }
        if (try DatabaseHandler.getSensorProfile(sensor.name) == nil){
            throw RLMError.InvalidSensorName
        }
        //check if the same combination of the sensorname and SourceName exists
        if (isExistingCombinationOfSourceAndSensorName(sensor.source, sensor.name)){
            throw RLMError.DuplicatedObjects
        }
        
        let realm = try! Realm()
        let rlmSensor = RLMSensor()
        realm.beginWrite()
        rlmSensor.id = getNextKeyForSensor()
        rlmSensor.name = sensor.name
        rlmSensor.meta =  JSONUtils.stringify(sensor.meta)
        rlmSensor.remoteUploadEnabled = sensor.remoteUploadEnabled
        rlmSensor.remoteDownloadEnabled = sensor.remoteDownloadEnabled
        rlmSensor.persistLocally = sensor.persistLocally
        rlmSensor.userId = sensor.userId
        rlmSensor.source = sensor.source
        rlmSensor.remoteDataPointsDownloaded = sensor.remoteDataPointsDownloaded
        rlmSensor.updateId()
        realm.add(rlmSensor)
        
        try realm.commitWrite()
        
        //update the id of sensor object
        sensor.id = rlmSensor.id
    }
    
    /**
    * Store the given sensor profile in database.
    * @param sensorName: String for the name of the sensor which the data structure belongs to.
    * @param dataStructure: String for the structure of the sensor.
    **/
    static func createOrUpdateSensorProfile(sensorName: String, dataStructure: String) throws {
        let realm = try! Realm()
        realm.beginWrite()
        let rlmSensorProfile = SensorProfile()
        rlmSensorProfile.sensorName = sensorName
        rlmSensorProfile.dataStructure = dataStructure
        realm.add(rlmSensorProfile, update: true)
  
        try realm.commitWrite()
    }
    
    /**
     * Returns the data structure of the requested sensor.
     * @param sensorName: String for the sensor name to specify data.
     **/
    static func getSensorProfile(sensorName: String) throws -> SensorProfile? {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "sensorName = %@", sensorName)
        let results = realm.objects(SensorProfile).filter(predicate)
        return results.first
    }
    
    static func getSensorProfiles() throws -> [SensorProfile] {
        var sensorProfiles = [SensorProfile]()
        let realm = try! Realm()
        let results = realm.objects(SensorProfile)
        for entry in results{
            sensorProfiles.append(entry)
        }
        return sensorProfiles
    }
    
    /**
    * Remove SensorProfile of the sensor with the given name.
    * @param sensorName: The name of sensor whose profile should be deleted.
    *
    **/
    static func deleteSensorProfile(sensorName: String) throws {
        let realm = try! Realm()
        let predicate = NSPredicate(format: "sensorName = %@", sensorName)
        let results = realm.objects(SensorProfile).filter(predicate)
        realm.beginWrite()
        for sensorProfile in results {
            realm.delete(sensorProfile)
        }

        try realm.commitWrite()
    }
    
    /**
    * Check if a sensor is already created in local storage
    * @param source  Name of the source
    * @param sensorName	  The name of the sensor
    * @return boolean: true if the sensor exists in local storage, and vice versa.
    **/
    static func hasSensor(source: String, sensorName: String) -> Bool {
        let realm = try! Realm()
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, self.getUserId())
        let results = realm.objects(RLMSensor).filter(predicates)
        if !results.isEmpty {
            return true
        }
        return false
    }
    
    /**
    * Returns a specific sensor with the given name and source.
    *
    * @param source: String for source.
    * @param sensorName: String for sensor name.
    * @return A sensor with the given sensor name and source.
    */
    static func getSensor(source: String, _ sensorName: String) throws -> Sensor {
        let realm = try! Realm()
        
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, self.getUserId())
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
    static func getSensors(source: String)->[Sensor]{
        var sensors = [Sensor]()
        let realm = try! Realm()
        
        let predicates = self.getPredicateForSensors(source)
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
    static func getSources()->[String]{
        var sources = Set<String>()
        let realm = try! Realm()
        let predicates = NSPredicate(format: "userId = %@", self.getUserId())
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
    static func getNextKeyForSensor() -> Int{
        let lockQueue = dispatch_queue_create("com.sense.key_generation_queue", nil)
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
    * Returns a compound predicate for querying DataPoints based on the arguments
    *
    * @param sensorId: Int for sensorId
    * @param startTime: NSDate for startTime
    * @param endTime: NSDate for endTime
    * @return A compound predicate for querying Sensors based on the arguments
    */
    private static func getPredicateForDataPoint(sensorId: Int, _ queryOptions: QueryOptions)-> NSPredicate{
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "sensorId = %d", sensorId))
        if(queryOptions.startTime != nil){
            predicates.append(NSPredicate(format: "time >= %f", queryOptions.startTime!.timeIntervalSince1970))
        }
        if(queryOptions.endTime != nil){
            predicates.append(NSPredicate(format: "time < %f" , queryOptions.endTime!.timeIntervalSince1970))
        }
        if(queryOptions.existsInRemote != nil){
            predicates.append(NSPredicate(format: "existsInRemote = %@" , queryOptions.existsInRemote!))
        }
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
    }
    
    /**
    * Returns a compound predicate for querying Sensors based on the arguments
    *
    * @param source: String for source
    * @param remoteDataPointsDownloaded: Bool for whether a sensor has completed the initial download of data points
    * @return A compound predicate for querying Sensors based on the arguments
    */
    private static func getPredicateForSensors(source: String)-> NSPredicate{
        var predicates = [NSPredicate]()
        predicates.append(NSPredicate(format: "source = %@ AND userId = %@", source, self.getUserId()))
        return NSCompoundPredicate.init(andPredicateWithSubpredicates: predicates)
    }

    /**
    * Returns a sensor with the given id.
    */
    private static func getSensor(id: Int) -> RLMSensor {
        var sensor = RLMSensor()
        let predicates = NSPredicate(format: "id = %d AND userId = %@", id, self.getUserId())
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            sensor = result.first!
        }
        return sensor
    }
    
    /**
    * Returns true if sensor with the given sensorId exists.
    */
    private static func isExistingPrimaryKeyForSensor(sensorId: Int) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "id = %d AND userId = %@", sensorId, self.getUserId())
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count == 1){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if source with the combination of the given source and sensor exists.
    */
    private static func isExistingCombinationOfSourceAndSensorName(source:String, _ sensorName: String) -> Bool {
        var exists = false
        let predicates = NSPredicate(format: "source = %@ AND name = %@ AND userId = %@", source, sensorName, self.getUserId())
        let result = try! Realm().objects(RLMSensor).filter(predicates)
        if(result.count > 0){
            exists = true
        }
        return exists
    }
    
    /**
    * Returns true if either of sensor name or source is changed.(Compound primary key)
    */
    private static func isPrimaryKeysChangedForSensor(new: Sensor, _ original:RLMSensor) -> Bool{
        let isNameChanged = (new.name != original.name)
        let isSourceChanged = (new.source != original.source)
        let isUserIdChanged = (new.userId != original.userId)
        return isNameChanged || isSourceChanged || isUserIdChanged
    }
    
    /**
    * Returns true if startTime is later or euqal to endTime.
    */
    private static func isStartTimeLaterThanEndTime(startTime: NSDate?, _ endTime: NSDate?) -> Bool {
        return (startTime != nil) && (endTime != nil) && (startTime?.timeIntervalSince1970 >= endTime?.timeIntervalSince1970)
    }
    
    private static func getUserId() -> String {
        return KeychainWrapper.stringForKey(KEYCHAIN_USERID)!
    }
}

