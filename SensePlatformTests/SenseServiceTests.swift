//
//  SensePlatformTestss.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/12/15.
//
//

import XCTest
@testable import SensePlatform
@testable import DSESwift

class SenseServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        CSSettings.sharedSettings().setSettingType(kCSSettingTypeGeneral, setting: kCSGeneralSettingUseStaging, value: kCSSettingYES)
        //CSSensePlatform.initializeWithApplicationKey("o4cbgFZjPPDA6GO32WipJBLnyazu8w4o")
    }
    
    override func tearDown() {
        print("----teardown----")
        super.tearDown()
    }
    
    func testInitialization() {
        // Arange: set expectation and callback
        let expectation = expectationWithDescription("wait for success callback")
        let completeHandler = {expectation.fulfill()}

        // Act: Login
        let sensorStore = self.createUniqueSensorStore()
        self.loginSenseService(sensorStore, completeHandler: completeHandler)
        
        // Assert: State of DSE
        let dse = DataStorageEngine.getInstance()
        XCTAssertEqual(dse.getStatus(), DSEStatus.INITIALIZED)
        
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
    func testRespawn() {
        // Arange: log in and initialize the senseService
        let expectation = expectationWithDescription("wait for success callback")
        let completeHandler = {expectation.fulfill()}
        var sensorStore = self.createUniqueSensorStore()
        self.loginSenseService(sensorStore, completeHandler: completeHandler)

        // Act: simulate respawn
        sensorStore = self.createUniqueSensorStore()
        sensorStore.sender.applicationKey = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o";
        
        // Assert: State of DSE should be initialized, because credentails and db contents should be persisted and global.
        let dse = DataStorageEngine.getInstance()
        XCTAssertEqual(dse.getStatus(), DSEStatus.INITIALIZED)
        waitForExpectationsWithTimeout(30, handler: nil)
    }
    
    func testCreateUniqueSensorStore(){
        let s1 = self.getSharedSensorStore()
        XCTAssertNotEqual(s1, self.createUniqueSensorStore());
    }
    
    func testGetSharedSensorStore(){
        let s1 = self.getSharedSensorStore()
        XCTAssertEqual(s1, self.getSharedSensorStore());
    }
    
    func createUniqueSensorStore() -> CSSensorStore{
        return CSSensorStore()
    }
    
    func getSharedSensorStore() -> CSSensorStore{
        return CSSensorStore.sharedInstance()
    }
    
    // MARK: helper class
    func loginSenseService(senseService: CSSensorStore, completeHandler: ()->Void){
        senseService.sender.applicationKey = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o";
        do{
            try senseService.loginWithUser("Username", andPassword: "Password", completeHandler: completeHandler, failureHandler: {})
        }catch{
            print(error)
            XCTFail()
        }
    }
    
}
