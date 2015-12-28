//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation

/**
 * This class provides the main interface for creating sensors and sources and setting storage engine specific properties.
 *
 * All the Data Storage Engine updates are delivered to the associated delegate object, which is a custom object that you provide.
 * For information about the delegate methods you use to receive events, see DataStorageEngineDelegate protocol.
 *
 * this is a singleton class: read how it works here:
 * http://krakendev.io/blog/the-right-way-to-write-a-singleton
*/
@objc public class DataStorageEngine: NSObject{
    // this makes the DSE a singleton!! woohoo!
    static let sharedInstance = DataStorageEngine()
    
    private var isSensorDownloadCompleted = false
    private var isSensorDataDownloadCompleted = false
    
    // get the config with default values
    private var config = DSEConfig()
    
    // reference to the datasyncer
    var dataSyncer = DataSyncer()
    
    private var dataSyncerCallbackHandler = DataSyncerCallbackHandler()

    
    //This prevents others from using the default '()' initializer for this class.
    private override init() {
        self.dataSyncer.delegate = dataSyncerCallbackHandler
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
        let backendEnvironment = customConfig.backendEnvironment
        configChanged = configChanged || self.config.backendEnvironment != customConfig.backendEnvironment
        self.config.backendEnvironment = backendEnvironment
        let backendStringValue = self.config.backendEnvironment == DSEServer.LIVE ? "LIVE" : "STAGING"
        
        // todo: do something with the encryption
        self.config.enableEncryption       = customConfig.enableEncryption       ?? self.config.enableEncryption
        
        
        // verify if we have indeed received valid credentials (not nil) and throw the appropriate error if something is wrong
        if (customConfig.sessionId != ""){self.config.sessionId = customConfig.sessionId}
        if (customConfig.userId != ""){self.config.userId = customConfig.userId}
        if (customConfig.appKey != ""){self.config.appKey = customConfig.appKey}
        
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.removeObjectForKey(DSEConstants.KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.sessionId, forKey: DSEConstants.KEYCHAIN_SESSIONID)
        
        // store the other options in the standardUserDefaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(self.config.syncInterval,           forKey: DSEConstants.SYNC_INTERVAL_KEY)
        defaults.setDouble(self.config.localPersistancePeriod, forKey: DSEConstants.LOCAL_PERSISTANCE_PERIOD_KEY)
        defaults.setObject(backendStringValue,                 forKey: DSEConstants.BACKEND_ENVIRONMENT_KEY)
        defaults.setBool(self.config.enableEncryption,         forKey: DSEConstants.ENABLE_ENCRYPTION_KEY)
        defaults.setObject(self.config.userId,                 forKey: DSEConstants.USERID_KEY)
        defaults.setObject(self.config.appKey,                 forKey: DSEConstants.APPKEY_KEY)
        
        if (configChanged) {
            if (self.dataSyncer.timer != nil){
                // Restart the timer in syncer to apply the new configurations.
                self.dataSyncer.stopPeriodicSync()
                self.dataSyncer.startPeriodicSync()
            }
        }
    }
    
    /**
    * Initialize DSE and start the timer for periodic syncing.
    **/
    public func start() throws {
        if (self.config.sessionId == "" || self.config.appKey == "" || self.config.userId == "") {
            // callback fail?
           throw DSEError.EmptyCredentials
        }
        
        NSLog("--- Starting DSE")
        if(!self.isInitialized()){
            NSLog("--- Not yet initialized")
            self.dataSyncer.initialize()
        }
        NSLog("--- Start timer")
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
        self.dataSyncerCallbackHandler = DataSyncerCallbackHandler()
        self.dataSyncer.delegate = self.dataSyncerCallbackHandler
    }
    



    /**
    * Returns a specific sensor by name and the source. It creates sensor if the sensor does not exist in the local storage.
    * @param source The name of the source
    * @param sensorName The name of the sensor
    **/
    public func getSensor(source: String, sensorName: String) throws -> Sensor{
        do{
            return try DatabaseHandler.getSensor(source, sensorName)
        }catch DSEError.ObjectNotFound {
            // sensor does not exist in local storage, create the sensor
            let sensorConfig = SensorConfig()
            let defaults = NSUserDefaults.standardUserDefaults()
            let sensor = Sensor(name: sensorName, source: source, sensorConfig: sensorConfig, userId: defaults.stringForKey(DSEConstants.USERID_KEY)!, remoteDataPointsDownloaded: true)
            try DatabaseHandler.insertSensor(sensor)
            dataSyncerCallbackHandler.onSensorCreated(sensor.name)
            return sensor
        }catch{
            print(error)
            throw error
        }
    }
    
    /**
    * Returns all the sensors connected to the given source
    * @return [Sensor] The sensors connected to the given source
    **/
    public func getSensors(source: String) throws -> [Sensor]{
        return try DatabaseHandler.getSensors(source)
    }
    
    /**
    * Returns all the sources attached to the current user
    * @return [String] The sources attached to the current user
    **/
    public func getSources() throws -> [String]{
        return try DatabaseHandler.getSources()
    }
    
    /**
     * Returns enum DSEStatus indicating status of DSE.
     * @return The DSEStatus, this could be either AWAITING_CREDENTIALS, AWAITING_SENSOR_PROFILES, READY.
     **/
    public func getStatus() -> DSEStatus{
        if(!self.areCredentialsPopulated()) {
            return DSEStatus.AWAITING_CREDENTIALS;
        } else if(self.isInitialized()) {
            return DSEStatus.INITIALIZED;
        } else {
            return DSEStatus.AWAITING_SENSOR_PROFILES;
        }
    }

    /**
    * Synchronizes the local data with Common Sense asynchronously
    * The results will be returned via AsyncCallback
    **/
    public func syncData(callback: DSEAsyncCallback){
        self.dataSyncer.sync(callback)
    }
    
    /**
    * Notifies when the sensors are downloaded asynchronously
    * @param callback The AsyncCallback method to call the success function on when the sensors are downloaded
    **/
    public func setSensorsDownloadedCallback(callback: DSEAsyncCallback){
        if self.isSensorDownloadCompleted{
            callback.onSuccess()
        } else {
            dataSyncerCallbackHandler.sensorsDownloadedCallbacks.append(callback)
        }
    }
    
    /**
    * Notifies when the sensor data are downloaded asynchronously
    * @param callback The AsyncCallback method to call the success function on when the sensor data is downloaded
    **/
    public func setSensorDataDownloadedCallback(callback: DSEAsyncCallback){
        if self.isSensorDataDownloadCompleted{
            callback.onSuccess()
        } else {
            dataSyncerCallbackHandler.sensorDataDownloadedCallbacks.append(callback)
        }
    }
    
    /**
    * Notifies when the initialization is done asynchronously
    * @param callback The AsyncCallback method to call the success function on when dse initialized
    **/
    public func setInitializationCallback(callback : DSEAsyncCallback){
        if (getStatus() == DSEStatus.INITIALIZED) {
            callback.onSuccess()
        } else {
            // status not ready yet. keep the callback in the array in DataSyncer
            dataSyncerCallbackHandler.initializationCallbacks.append(callback)
        }
    }
    
    /**
     * Add a handler for sensor creation. The callback will be triggered whenever a sensor is created in local storage,
     * such as on download of sensor from remote or on getSensor() call but sensor does not exists.
     * The callback will not be removed until removeSensorCreationHandler is called.
     * @param callback A closure to handle the exception
     * @return returns String for uuid to identify the closure.
     **/
    public func setSensorCreationHandler(sensorCreationHandler :(sensorName: String)->Void) -> String{
        let uuid = NSUUID().UUIDString
        dataSyncerCallbackHandler.sensorCreationHandlers[uuid] = sensorCreationHandler
        return uuid
    }
    
    /**
     * Remove the closure with the given uuid.
     * @param uuid String for uuid of the closure to be removed.
     * @return true if the handler is removed. false if the handler is not in the dictionary.
     **/
    public func removeSensorCreationHandler(uuid: String) -> Bool{
        if (dataSyncerCallbackHandler.exceptionHandlers.removeValueForKey(uuid) != nil){
            return true
        }else{
            return false
        }
    }
    
    /**
     * Add an exception handler for sync process to the dictionary of sync exception handlers.
     * The callback will not be removed until removeSyncExceptionHandler is called.
     * @param callback A closure to handle the exception
     * @return returns String for uuid to identify the closure.
     **/
    public func setSyncExceptionHandler(exceptionHandler : (error: ErrorType)->Void) -> String{
        let uuid = NSUUID().UUIDString
        dataSyncerCallbackHandler.exceptionHandlers[uuid] = exceptionHandler
        return uuid
    }
    
    /**
     * Remove the closure with the given uuid.
     * @param uuid String for uuid of the closure to be removed.
     * @return true if the handler is removed. false if the handler is not in the dictionary.
     **/
    public func removeSyncExceptionHandler(uuid: String) -> Bool {
        if (dataSyncerCallbackHandler.exceptionHandlers.removeValueForKey(uuid) != nil){
            return true
        }else{
            return false
        }
    }
    
    private func isInitialized() -> Bool {
        if (self.areCredentialsPopulated() && dataSyncer.areSensorProfilesPopulated()){
            return true
        }else{
            return false
        }
    }
    
    private func areCredentialsPopulated() -> Bool {
        if (self.config.sessionId != "" && self.config.appKey != "" && self.config.userId != ""){
            return true
        }else{
            return false
        }
    }
    

    
    private class DataSyncerCallbackHandler: DataSyncerDelegate{
        
        // callbacks
        var initializationCallbacks = [DSEAsyncCallback]()
        var sensorsDownloadedCallbacks = [DSEAsyncCallback]()
        var sensorDataDownloadedCallbacks = [DSEAsyncCallback]()
        var sensorCreationHandlers = Dictionary<String ,(sensorName: String) -> Void>()
        var exceptionHandlers = Dictionary<String ,(error:DSEError) -> Void>()
    
        func onInitializationCompleted() {
            for callback in initializationCallbacks{
                callback.onSuccess()
                initializationCallbacks.removeFirst()
            }
        }
        
        func onInitializationFailed(error:DSEError) {
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
        
        func onSensorsDownloadFailed(error: DSEError){
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
        
        func onSensorDataDownloadFailed(error: DSEError) {
            for callback in sensorDataDownloadedCallbacks{
                callback.onFailure(error)
            }
        }
        
        func onSensorCreated(sensorName: String) {
            for (_, sensorCreationhandler) in sensorCreationHandlers{
                sensorCreationhandler(sensorName: sensorName)
            }
        }
        
        func onException(error:DSEError){
            for (_, exceptionHandler) in exceptionHandlers{
                exceptionHandler(error: error)
            }
        }
    }
}