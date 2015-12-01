//
//  DSEConfig.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/12/15.
//
//

import Foundation

@objc public class DSEConfig: NSObject{
    public var syncInterval: Double = 30 * 60// amount of seconds between upload sessions (default: 30 minutes)
    public var localPersistancePeriod: Double = 30 * 24 * 60 * 60 // amount of seconds to persist history (default: 30 days)
    public var enablePeriodicSync: Bool = true // whether enable the periodic sync or not (default: true)
    public var enableEncryption: Bool = true // whether enable the encryption or not (default: true)
    public var backendEnvironment: DSEServer = DSEServer.STAGING // the backend environment to use  (LIVE / STAGING)
    public var appKey: String = ""// credentials: appKey
    public var sessionId: String = "" // credentials: sessionId
    public var userId: String = "" // credentials: userId from CS
}