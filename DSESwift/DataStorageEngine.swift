//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation
import PromiseKit

/**
 * This class provides the main interface for creating sensors and sources and setting storage engine specific properties.
 *
 * All the Data Storage Engine updates are delivered to the associated delegate object, which is a custom object that you provide.
 * For information about the delegate methods you use to receive events, see DataStorageEngineDelegate protocol.
 *
 * this is a singleton class: read how it works here:
 * http://krakendev.io/blog/the-right-way-to-write-a-singleton
*/
public class DataStorageEngine{
    // this makes the DSE a singleton!! woohoo!
    static let sharedInstance = DataStorageEngine()
    
    private var isSensorDownloadCompleted = false
    private var isSensorDataDownloadCompleted = false
    
    // get the config with default values
    private var config = DSEConfig()
    
    // reference to the datasyncer
    var dataSyncer = DataSyncer()
    
    private var dataSyncerProgressHandler = DataSyncerProgressHandler()

    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        self.dataSyncer.delegate = dataSyncerProgressHandler
    }
    
    /**
     * Return the singleton DSE object.
     * @return sharedInstance: the singleton DSE object.
     **/
    public static func getInstance() -> DataStorageEngine {
        return sharedInstance
    }
    
    /**
     * Set up the configration for DSE.
     * @param customConfig: DSEConfig holding the configuration to be applied.
     **/
    public func setup(customConfig: DSEConfig) throws {
        // set config for DataSyncer
        var (configChanged, syncInterval, localPersistancePeriod, enablePeriodicSync) = try self.dataSyncer.setConfig(customConfig)
        
        self.config.syncInterval           = syncInterval
        self.config.localPersistancePeriod = localPersistancePeriod
        self.config.enablePeriodicSync = enablePeriodicSync
        
        // check for changed in the backend environment
        if let backendEnvironment = customConfig.backendEnvironment {
            configChanged = configChanged || self.config.backendEnvironment != customConfig.backendEnvironment
            self.config.backendEnvironment = backendEnvironment
        }
        let backendStringValue = self.config.backendEnvironment! == DSEServer.LIVE ? "LIVE" : "STAGING"
        
        // todo: do something with the encryption
        self.config.enableEncryption       = customConfig.enableEncryption       ?? self.config.enableEncryption
        
        
        // verify if we have indeed received valid credentials (not nil) and throw the appropriate error if something is wrong
        if let appKey    = customConfig.appKey {self.config.appKey = appKey}       else { throw DSEError.InvalidAppKey }
        if let sessionId = customConfig.sessionId {self.config.sessionId = sessionId} else { throw DSEError.InvalidSessionId }
        if let userId    = customConfig.userId {self.config.userId = userId}       else { throw DSEError.InvalidUserId }
        
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId!, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey!,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.config.userId!,    forKey: KEYCHAIN_USERID)
        
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(self.config.syncInterval!,           forKey: DSEConstants.SYNC_INTERVAL_KEY)
        defaults.setDouble(self.config.localPersistancePeriod!, forKey: DSEConstants.LOCAL_PERSISTANCE_PERIOD_KEY)
        defaults.setObject(backendStringValue,                  forKey: DSEConstants.BACKEND_ENVIRONMENT_KEY)
        defaults.setBool(self.config.enableEncryption!,         forKey: DSEConstants.ENABLE_ENCRYPTION_KEY)
        
        if (configChanged) {
            // do something? reinit the syncer?
            // if the timer in data syncer is running, then we should re-start the syncer
            // if the timer in data syncer is not running, then no need of change
        }
    }
    
    /**
    * Initialize DSE and start the timer for periodic syncing.
    **/
    public func start() throws {
        if (self.config.sessionId == nil || self.config.appKey == nil || self.config.userId == nil) {
            // callback fail?
           throw DSEError.EmptyCredentials
        }
        
        self.dataSyncer.initialize()
        self.dataSyncer.startPeriodicSync()
    }
    
    /**
     * Stop the timer for periodic syncing.
     **/
    public func stopPeriodicSync(){
        self.dataSyncer.stopPeriodicSync()
    }
    
    /**
     * Reset DataStorage Engine. The configuration, callbacks, the timer for the syncing will be reset.
     **/
    func reset(){
        self.config = DSEConfig()
        self.dataSyncer = DataSyncer()
        self.dataSyncerProgressHandler = DataSyncerProgressHandler()
        self.dataSyncer.delegate = self.dataSyncerProgressHandler
    }
    
    /**
    * Create a new sensor in database and backend if it does not already exist.
    * @param source The source name (e.g accelerometer)
    * @param name The sensor name (e.g accelerometer)
    * @param sensorConfig The sensor options
    * @return The newly created sensor object
    * //TODO: List possible exceptions
    **/
    func createSensor(source: String, name: String, sensorConfig: SensorConfig = SensorConfig()) throws -> Sensor{
        let sensor = Sensor(name: name, source: source, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: true)
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
        if(self.config.sessionId == nil || self.config.appKey == nil || self.config.userId == nil) {
            return DSEStatus.AWAITING_CREDENTIALS;
        } else if(self.dataSyncer.initialized) {
            return DSEStatus.INITIALIZED;
        } else {
            return DSEStatus.AWAITING_SENSOR_PROFILES;
        }
    }

    /**
    * Synchronizes the local data with Common Sense asynchronously
    * The results will be returned via AsyncCallback
    **/
    func syncData(callback: DSEAsyncCallback){
        self.dataSyncer.sync(callback)
    }
    
    /**
    * Notifies when the sensors are downloaded asynchronously
    * @param callback The AsyncCallback method to call the success function on when the sensors are downloaded
    **/
    func setSensorsDownloadedCallback(callback: DSEAsyncCallback){
        if self.isSensorDownloadCompleted{
            callback.onSuccess()
        } else {
            dataSyncerProgressHandler.sensorsDownloadedCallbacks.append(callback)
        }
    }
    
    /**
    * Notifies when the sensor data are downloaded asynchronously
    * @param callback The AsyncCallback method to call the success function on when the sensor data is downloaded
    **/
    func setSensorDataDownloadedCallback(callback: DSEAsyncCallback){
        if self.isSensorDataDownloadCompleted{
            callback.onSuccess()
        } else {
            dataSyncerProgressHandler.sensorDataDownloadedCallbacks.append(callback)
        }
    }
    
    /**
    * Notifies when the initialization is done asynchronously
    * @param callback The AsyncCallback method to call the success function on when dse initialized
    **/
    func setInitializationCallback(callback : DSEAsyncCallback){
        if (getStatus() == DSEStatus.INITIALIZED) {
            callback.onSuccess()
        } else {
            // status not ready yet. keep the callback in the array in DataSyncer
            dataSyncerProgressHandler.initializationCallbacks.append(callback)
        }
    }
    
    /**
     * Add an exception handler for sync process to the dictionary of sync exception handlers.
     * The callback will not be removed until removeSyncExceptionHandler is called.
     * @param callback A closure to handle the exception
     * @return returns String for uuid to identify the closure.
     **/
    func setSyncExceptionHandler(exceptionHandler : (error: ErrorType)->Void) -> String{
        let uuid = NSUUID().UUIDString
        dataSyncerProgressHandler.exceptionHandlers[uuid] = exceptionHandler
        return uuid
    }
    
    /**
     * Remove the closure with the given uuid.
     * @param uuid String for uuid of the closure to be removed.
     * @return true if the handler is removed. false if the handler is not in the dictionary.
     **/
    func removeSyncExceptionHandler(uuid: String) -> Bool {
        if (dataSyncerProgressHandler.exceptionHandlers.removeValueForKey(uuid) != nil){
            return true
        }else{
            return false
        }
    }
    
    private class DataSyncerProgressHandler: DataSyncerDelegate{
        
        // callbacks
        var initializationCallbacks = [DSEAsyncCallback]()
        var sensorsDownloadedCallbacks = [DSEAsyncCallback]()
        var sensorDataDownloadedCallbacks = [DSEAsyncCallback]()
        var exceptionHandlers = Dictionary<String ,(error:ErrorType) -> Void>()
    
        func onInitializationCompleted() {
            for callback in initializationCallbacks{
                callback.onSuccess()
                initializationCallbacks.removeFirst()
            }
        }
        
        func onInitializationFailed(error:ErrorType) {
            for callback in initializationCallbacks{
                callback.onFailure(error)
            }
        }
        
        func onSensorsDownloadCompleted() {
            for callback in sensorsDownloadedCallbacks{
                callback.onSuccess()
                sensorsDownloadedCallbacks.removeFirst()
            }
        }
        
        func onSensorsDownloadFailed(error: ErrorType){
            for callback in sensorDataDownloadedCallbacks{
                callback.onFailure(error)
            }
        }
        
        func onSensorDataDownloadCompleted() {
            for callback in sensorDataDownloadedCallbacks{
                callback.onSuccess()
                sensorDataDownloadedCallbacks.removeFirst()
            }
        }
        
        func onSensorDataDownloadFailed(error: ErrorType) {
            for callback in sensorDataDownloadedCallbacks{
                callback.onFailure(error)
            }
        }
        
        func onException(error:ErrorType){
            for (_, handler) in exceptionHandlers{
                handler(error: error)
            }
        }
    }
}