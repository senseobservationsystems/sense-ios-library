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
    case InvalidAppKey
    case InvalidSessionId
    case InvalidUserId
}

let SYNC_INTERVAL_KEY = "DSE_syncInterval"
let LOCAL_PERSISTANCE_PERIOD_KEY = "DSE_localPersistancePeriod"
let BACKEND_ENVIRONMENT_KEY = "DSE_backendEnvironment"
let ENABLE_ENCRYPTION_KEY = "DSE_enableEncryption"


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
    
    // get the config with default values
    private var config = DSEConfig()
    
    // reference to the datasyncer
    let dataSyncer = DataSyncer()
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        // todo: get config from keychain and user defaults?
    }

    
    public static func getInstance() -> DataStorageEngine {
        return sharedInstance
    }
    
    public func setup(customConfig: DSEConfig) throws {
        var (configChanged, syncInterval, localPersistancePeriod) = try self.dataSyncer.setConfig(self.config)
        
        self.config.syncInterval           = syncInterval
        self.config.localPersistancePeriod = localPersistancePeriod
        
        // check for changed in the backend environment
        if let backendEnvironment = customConfig.backendEnvironment {
            configChanged = configChanged || self.config.backendEnvironment != customConfig.backendEnvironment
            self.config.backendEnvironment = backendEnvironment
        }
        let backendStringValue = self.config.backendEnvironment! == SensorDataProxy.Server.LIVE ? "LIVE" : "STAGING"
        
        // todo: do something with the encryption
        self.config.enableEncryption       = customConfig.enableEncryption       ?? self.config.enableEncryption
        
        // verify if we have indeed received valid credentials (not nil) and throw the appropriate error if something is wrong
        if let appKey    = self.config.appKey {self.config.appKey = appKey}       else { throw DatabaseError.InvalidAppKey }
        if let sessionId = self.config.appKey {self.config.sessionId = sessionId} else { throw DatabaseError.InvalidSessionId }
        if let userId    = self.config.userId {self.config.userId = userId}       else { throw DatabaseError.InvalidUserId }
        
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId!, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey!,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.config.userId!,    forKey: KEYCHAIN_USERID)
        
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(self.config.syncInterval!,           forKey: SYNC_INTERVAL_KEY)
        defaults.setDouble(self.config.localPersistancePeriod!, forKey: LOCAL_PERSISTANCE_PERIOD_KEY)
        defaults.setObject(backendStringValue,                  forKey: BACKEND_ENVIRONMENT_KEY)
        defaults.setBool(self.config.enableEncryption!,         forKey: ENABLE_ENCRYPTION_KEY)
        
        if (configChanged) {
            // do something? reinit the syncer?
        }
    }
    
    public func start() {
        // todo: check if we have credentials!
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