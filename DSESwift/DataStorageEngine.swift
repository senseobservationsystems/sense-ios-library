//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation

enum DatabaseError: ErrorType{
    case ObjectNotFound
    case InsertFailed
    case UpdateFailed
    case DuplicatedObjects
    case InvalidLimit
    case UnauthenticatedAccess
    case UnknownError
}


/**
 * This class provides the main interface for creating sensors and sources and setting storage engine specific properties.
 *
 * All the Data Storage Engine updates are delivered to the associated delegate object, which is a custom object that you provide.
 * For information about the delegate methods you use to receive events, see DataStorageEngineDelegate protocol.
 *
 * this is a singleton class: read how it works here:
 * http://krakendev.io/blog/the-right-way-to-write-a-singleton
*/
public class DataStorageEngine {
    // this makes the DSE a singleton!! woohoo!
    static let sharedInstance = DataStorageEngine()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        
    }
    
    public static func getInstance() -> DataStorageEngine {
        return sharedInstance
    }
    
    /**
    * Create a new sensor in database and backend if it does not already exist. Throw exception if it already exists. If it has been created, return the object.
    * an object.
    * @param name The sensor name (e.g accelerometer)
    * @param dataType The data type of the sensor
    * @param options The sensor options
    * @return sensor object
    **/
    public func createSensor(source: String, name: String, sensorConfig: SensorConfig) throws -> Sensor
    {
        let sensor = Sensor(name: name, source: source, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
        try DatabaseHandler.insertSensor(sensor)

        return sensor
    }

    /**
    * Returns a specific sensor by name and the source it belongs to
    * @param source The name of the source
    * @param sensorName The name of the sensor
    **/
    public func getSensor(source: String, sensorName : String) throws -> Sensor?{
        var sensor : Sensor?
        sensor = try DatabaseHandler.getSensor(source, sensorName)
        return sensor
    }
    
    /**
    * Returns all the sensors connected to the given source
    * @return [Sensor] The sensors connected to the given source
    **/
    public func getSensors(source: String) -> [Sensor]{
        return DatabaseHandler.getSensors(source)
    }
    
    /**
    * Returns all the sources attached to the current user
    * @return [String] The sources attached to the current user
    **/
    public func getSources() -> [String]{
        return DatabaseHandler.getSources()
    }
    
    public func setCredentials(credentials: String) -> Void {
        
    }
}