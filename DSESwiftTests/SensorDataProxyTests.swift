//
//  SensorDataProxyTests.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 15/10/15.
//
//

import XCTest
@testable import DSESwift
@testable import SwiftyJSON

class SensorDataProxyTests: XCTestCase {
    
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    var accountUtils: CSAccountUtils?
    
    override func setUp() {
        super.setUp()
        let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
        
        accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils!.registerUser(username, password: "Password")
        accountUtils!.loginUser(username, password: "Password")
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTest() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: "")
        proxy.test()
    }
    
    func testTestPost() {
        let accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
        accountUtils.testPOST()
    }
    
    func testRegistrationAndDelete(){
        accountUtils!.deleteUser()
    }
    
    
    func testGetSensor() {
        let proxy = SensorDataProxy(server: SensorDataProxy.Server.STAGING, appKey: APPKEY_STAGING, sessionId: (accountUtils?.sessionId)!)
        do{
            let sourceName = "aim-ios-sdk"
            let sensorName = "accelerometer"
            let dataPoint = ["x": 4, "y": 5, "z": 6]
            var data = Array<AnyObject>()
            for _ in 1...100 {
                data.append(dataPoint)
            }
            
            proxy.putSensorData(sourceName: sourceName, sensorName: sensorName, data: data, meta: nil)
            let json = try proxy.getSensors()
            debugPrint(json)
        }catch{
            print(error)
        }
    }
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
