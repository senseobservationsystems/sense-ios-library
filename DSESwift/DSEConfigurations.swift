//
//  SensorConfig.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public struct SensorConfig{
    var meta : Dictionary<String, AnyObject>? = nil  // null by default, if not null, change from default
    var uploadEnabled: Bool? = true// null by default, if not null, change from default
    var downloadEnabled: Bool? = true// null by default, if not null, change from default
    var persist: Bool? = true// null by default, if not null, change from default
}

public struct DSEConfig{
    var syncInterval: Double? // amount of seconds between upload sessions (default: 30 minutes)
    var localPersistancePeriod: Double?  // amount of seconds to persist history (default: 30 days)
    var enableEncryption: Bool? // whether enable the encryption or not (default: true)
    var backendEnvironment: SensorDataProxy.Server? // the backend environment to use  (LIVE / STAGING)
    var appKey: String? // credentials: appKey
    var sessionId: String? // credentials: sessionId
}