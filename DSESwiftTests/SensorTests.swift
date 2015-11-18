//
//  SensorTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 18/11/15.
//
//

import XCTest
@testable import DSESwift
import RealmSwift
import SwiftyJSON

class SensorTests: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    var config = DSEConfig()
    let userId = "testuser"
    let dataSyncer = DataSyncer()
    
    override func setUp() {
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        KeychainWrapper.setString(userId, forKey: KEYCHAIN_USERID)
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        registerAndLogin()
        
        // set the config with CORRECT default values
        self.config.syncInterval           = 30 * 60
        self.config.localPersistancePeriod = 30 * 24 * 60 * 60
        self.config.enableEncryption       = true
        self.config.backendEnvironment     = SensorDataProxy.Server.STAGING
        self.config.appKey = APPKEY_STAGING
        self.config.sessionId = (accountUtils?.sessionId)!
        
        do{
            try self.dataSyncer.setConfig(self.config)
        } catch {
            XCTFail("Fail in setup")
        }
        // store the credentials in the keychain. All modules that need these will get them from the chain
        KeychainWrapper.setString(self.config.sessionId!, forKey: KEYCHAIN_SESSIONID)
        KeychainWrapper.setString(self.config.appKey!,    forKey: KEYCHAIN_APPKEY)
        KeychainWrapper.setString(self.userId, forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInsertAndGetDataPoint_withCorrectDictionaryValue_insertDataPointToLocalDatabase() {
        do{
            // Arrange: Make sensor object.
            let sensorConfig = SensorConfig()
            let sensor = Sensor(name: "accelerometer", source: "aim-ios-sdk", sensorConfig: sensorConfig, userId: userId, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            let value = ["x-axis": 3, "y-axis": 4, "z-axis": 5]
            
            // Act: insert the datapiont
            try sensor.insertOrUpdateDataPoint(value, NSDate())
        
            // Assert:
            let queryOptions = QueryOptions()
            let retrievedDataPoint = try sensor.getDataPoints(queryOptions)
            XCTAssertEqual(JSON(value), JSON(retrievedDataPoint[0].getValueInDictionary()))
        }catch{
            print(error)
            XCTFail("exception is captured. Abort the test.")
        }
    }

    
}
