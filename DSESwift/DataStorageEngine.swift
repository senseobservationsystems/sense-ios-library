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
    case EmptyCredentials
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
public class DataStorageEngine: DataSyncerDelegate{
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
    
    // callbacks
    var readyCallbacks = [DSEAsyncCallback]()
    var sensorsDownloadedCallbacks = [DSEAsyncCallback]()
    var sensorDataDownloadedCallbacks = [DSEAsyncCallback]()
    var syncCompleteHandlers = [DSEAsyncCallback]()
    
    private var isSensorDownloadCompleted = false
    private var isSensorDataDownloadCompleted = false
    
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
        // set config for DataSyncer
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
        if let appKey    = customConfig.appKey {self.config.appKey = appKey}       else { throw DatabaseError.InvalidAppKey }
        if let sessionId = customConfig.sessionId {self.config.sessionId = sessionId} else { throw DatabaseError.InvalidSessionId }
        if let userId    = customConfig.userId {self.config.userId = userId}       else { throw DatabaseError.InvalidUserId }
        
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
            // if the timer in data syncer is running, then we should re-start the sync
            // if the timer in data syncer is not running, then no need of change
        }
    }
    
    public func start() throws {
        if (self.config.sessionId == nil || self.config.appKey == nil || self.config.userId == nil) {
            // callback fail?
           throw DatabaseError.EmptyCredentials
        }
        
        self.dataSyncer.delegate = self
        self.dataSyncer.initialize()
        self.dataSyncer.enablePeriodicSync()
    }
    
    public func stopPeriodicSync(){
        self.dataSyncer.disablePeriodicSync()
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
        if(self.config.sessionId == nil) {
            return DSEStatus.AWAITING_CREDENTIALS;
        } else if(self.dataSyncer.initialized) {
            return DSEStatus.READY;
        } else {
            return DSEStatus.AWAITING_SENSOR_PROFILES;
        }
    }

    /**
    * Synchronizes the local data with Common Sense asynchronously
    * The results will be returned via AsyncCallback
    **/
    func syncData() throws {
        self.dataSyncer.sync()
    }
    
    /**
    * Notifies when the sensors are downloaded asynchronously
    * @param callback The AsyncCallback method to call the success function on when the sensors are downloaded
    **/
    func setSensorsDownloadedCallback(callback: DSEAsyncCallback){
        if self.isSensorDownloadCompleted{
            callback.onSuccess()
        } else {
            self.sensorsDownloadedCallbacks.append(callback)
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
            self.sensorDataDownloadedCallbacks.append(callback)
        }
    }
    
    /**
    * Notifies when the initialization is done asynchronously
    * @param callback The AsyncCallback method to call the success function on when ready
    **/
    func setReadyCallback(callback : DSEAsyncCallback){
        if (getStatus() == DSEStatus.READY) {
            callback.onSuccess()
        } else {
            // status not ready yet. keep the callback in the array in DataSyncer
            self.readyCallbacks.append(callback)
        }
    }
    
    /**
     * Notifies on completion of the first sync since you set the callback.
     * @param callback The AsyncCallback method to call the success function on when ready
     **/
    func setSyncCompletedCallback(callback : DSEAsyncCallback){
        // status not ready yet. keep the callback in the array in DataSyncer
        self.syncCompleteHandlers.append(callback)
    }
    
    func onInitializationCompleted() {
        for callback in readyCallbacks{
            callback.onSuccess()
            readyCallbacks.removeFirst()
        }
    }
    
    func onInitializationFailed(error:ErrorType) {
        for callback in readyCallbacks{
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
    
    func onSyncCompleted() {
        for callback in syncCompleteHandlers{
            callback.onSuccess()
            syncCompleteHandlers.removeFirst()
        }
    }
    
    func onSyncFailed(error: ErrorType) {
        for callback in syncCompleteHandlers{
            callback.onFailure(error)
            syncCompleteHandlers.removeFirst()
        }
    }
}