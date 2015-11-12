//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation

public enum DatabaseError: ErrorType{
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
    private var config = DSEConfig()
    
    // reference to the datasyncer
    let dataSyncer = DataSyncer()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        // set default config
        self.setDefaultConfig();
    }
    
    func setDefaultConfig() {
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
    }
    
    public static func getInstance() -> DataStorageEngine {
        return sharedInstance
    }
    
    public func setup(customConfig: DSEConfig) {
        self.config.syncInterval           = customConfig.syncInterval           ?? self.config.syncInterval
        self.config.localPersistancePeriod = customConfig.localPersistancePeriod ?? self.config.localPersistancePeriod
        self.config.enableEncryption       = customConfig.enableEncryption       ?? self.config.enableEncryption
        self.config.backendEnvironment     = customConfig.backendEnvironment     ?? self.config.backendEnvironment
        self.config.appKey                 = customConfig.appKey!
        self.config.sessionId              = customConfig.sessionId!
        
        self.dataSyncer.setConfig(self.config)
    }
    
    public func start() {
        
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