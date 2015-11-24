//
//  SensorConfig.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public struct SensorConfig{
    var meta: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()  // null by default, if not null, change from default
    var uploadEnabled: Bool = false// null by default, if not null, change from default
    var downloadEnabled: Bool = false// null by default, if not null, change from default
    var persist: Bool = false// null by default, if not null, change from default
}

public struct DSEConfig{
    var syncInterval: Double? = 30 * 60// amount of seconds between upload sessions (default: 30 minutes)
    var localPersistancePeriod: Double? = 30 * 24 * 60 * 60 // amount of seconds to persist history (default: 30 days)
    var enablePeriodicSync: Bool? = true // whether enable the periodic sync or not (default: true)
    var enableEncryption: Bool? = true // whether enable the encryption or not (default: true)
    var backendEnvironment: DSEServer? = DSEServer.STAGING // the backend environment to use  (LIVE / STAGING)
    var appKey: String? // credentials: appKey
    var sessionId: String? // credentials: sessionId
    var userId: String? // credentials: userId from CS
}