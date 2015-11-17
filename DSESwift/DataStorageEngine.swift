//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation
import PromiseKit

public enum DatabaseError: ErrorType{
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
    
    /**
     * The possible statuses of the DataStorageEngine
     * AWAITING_CREDENTIALS = there are not credentials set, setCredentials needs to be called
     * AWAITING_SENSOR_PROFILES = the credentials are set and the sensor profiles are being downloaded
     * READY = the engine is ready for use
     */
    public enum DSEStatus{
        case AWAITING_CREDENTIALS
        case AWAITING_SENSOR_PROFILES
        case READY
    }
    
    // get the config with default values
    private var config = DSEConfig()
    
    // reference to the datasyncer
    let dataSyncer = DataSyncer()
    
    private var initialized = false
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        // todo: get config from keychain and user defaults?
    }

    
    public static func getInstance() -> DataStorageEngine {
        return sharedInstance
    }
    
    public func setup(customConfig: DSEConfig) throws {
        var (configChanged, syncInterval, localPersistancePeriod) = try self.dataSyncer.setConfig(customConfig)
        
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
        if (self.config.sessionId == nil || self.config.appKey == nil || self.config.userId == nil) {
            // callback fail?
            print("NO CREDENTIALS")
        }
        
        self.dataSyncer.initialize().then({
            //TODO: callback success?
        }).error({error in
            //TODO: callback fail?
            print(error)

        })
    }
    
    /**
    * Create a new sensor in database and backend if it does not already exist.
    * @param source The source name (e.g accelerometer)
    * @param name The sensor name (e.g accelerometer)
    * @param options The sensor options
    * @return The newly created sensor object
    * //TODO: List possible exceptions
    **/
    func createSensor(source: String, name: String, options: SensorConfig) throws -> Sensor{
        let sensor = Sensor(name: name, source: source, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: true)
        try DatabaseHandler.insertSensor(sensor)
        return sensor
    }

    /**
    * Returns a specific sensor by name and the source it belongs to
    * @param source The name of the source
    * @param sensorName The name of the sensor
    **/
    public func getSensor(source: String, sensorName : String) throws -> Sensor?{
        return try DatabaseHandler.getSensor(source, sensorName)
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
    
    /**
     * Returns enum DSEStatus indicating status of DSE.
     * @return The DSEStatus, this could be either AWAITING_CREDENTIALS, AWAITING_SENSOR_PROFILES, READY.
     **/
    public func getStatus() -> DSEStatus{
        if(self.config.sessionId == nil) {
            return DSEStatus.AWAITING_CREDENTIALS;
        } else if(self.initialized) {
            return DSEStatus.READY;
        } else {
            return DSEStatus.AWAITING_SENSOR_PROFILES;
        }
    }

    /**
    * Synchronizes the local data with Common Sense asynchronously
    * The results will be returned via AsyncCallback
    **/
    func syncData(completionHandler : DSEAsyncCallback){
        
    }
    
    /**
    * Notifies when the sensors are downloaded asynchronously
    * The sensors are automatically downloaded when the DataStorageEngine is ready
    * @param callback The AsyncCallback method to call the success function on when the sensors are downloaded
    **/
    func onSensorsDownloaded(callback: DSEAsyncCallback){
        //How do we check this????
    }
    
    /**
    * Notifies when the sensors are downloaded asynchronously
    * The sensor data is automatically downloaded when the DataStorageEngine is ready
    * @param callback The AsyncCallback method to call the success function on when the sensor data is downloaded
    **/
    func onSensorDataDownloaded(callback: DSEAsyncCallback){
        //Check the download status of all the sensors
    }
    
    /**
    * Notifies when the initialization is done asynchronously
    * The initialization is done when the credentials have been set and sensor profiles downloaded.
    * @param callback The AsyncCallback method to call the success function on when ready
    **/
    func onReady(callback : DSEAsyncCallback){
        if (getStatus() != DSEStatus.READY) {
            // status not ready yet. keep the callback in the array in DataSyncer
            // TODO: Should we store this in the DSE or DataSyncer?
            self.dataSyncer.readyCallbacks.append(callback)
        } else {
            callback.onSuccess()
        }
    }
    
}