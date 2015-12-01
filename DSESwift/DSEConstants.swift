//
//  DSEConstants.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 20/11/15.
//
//

import Foundation

public struct DSEConstants{
    static let SYNC_INTERVAL_KEY = "DSE_syncInterval"
    static let LOCAL_PERSISTANCE_PERIOD_KEY = "DSE_localPersistancePeriod"
    static let BACKEND_ENVIRONMENT_KEY = "DSE_backendEnvironment"
    static let ENABLE_ENCRYPTION_KEY = "DSE_enableEncryption"
    
    // for data types
    static let DATA_TYPE_STRING = "string"
    static let DATA_TYPE_JSON = "json"
    static let DATA_TYPE_INTEGER = "integer"
    static let DATA_TYPE_FLOAT = "float"
    static let DATA_TYPE_BOOL = "bool"
    
    // for syncing
    // 1000 datapoints is a safe amount for a respond not to exceed the maximum data size of respond in CommonSense
    static let DEFAULT_REMOTE_QUERY_LIMIT = 1000
    
    // for sensor profile
    static let SENSOR_PROFILE_KEY_NAME = "sensor_name"
    static let SENSOR_PROFILE_KEY_STRUCTURE = "data_structure"
    
    // for queues
    static let DATASYNCER_PROCESS_QUEUE_ID = "nl.sense.dse.sync_process_queue"
}

@objc public enum DSEError: Int, ErrorType{
    // Database Handler
    case ObjectNotFound
    case DuplicatedObjects
    case InvalidLimit
    case StartTimeLaterThanEndTime
    case UnauthenticatedAccess
    case CanNotChangePrimaryKey
    case InvalidSensorName
    // DSE
    case InvalidAppKey
    case InvalidSessionId
    case InvalidUserId
    case EmptyCredentials
    case IncorrectDataStructure
    case UnknownDataType
    case DSENotReady
    // Proxy
    case InvalidSensorOrSourceOrBadStructure //thrown when invalid sensorName/sourceName/structure is given
    case InvalidDataFormat
    case InvalidQuery
    case SensorDoesNotExist
    case UnknownError
    // DataSyncer 
    case InvalidPersistentPeriod
    case InvalidSyncRate
}

/**
 * The possible statuses of the DataStorageEngine
 * AWAITING_CREDENTIALS = there are not credentials set, setCredentials needs to be called
 * AWAITING_SENSOR_PROFILES = the credentials are set and the sensor profiles are being downloaded
 * READY = the engine is ready for use
 */
@objc public enum DSEStatus: Int{
    case AWAITING_CREDENTIALS
    case AWAITING_SENSOR_PROFILES
    case INITIALIZED
}

@objc public enum DSEServer: Int{
    case LIVE = 0
    case STAGING
}