//
//  TestHelper.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 24/12/15.
//
//

import XCTest

class TestHelper{

    func createUniqueSensorStore() -> CSSensorStore{
        return CSSensorStore()
    }
    
    func getSharedSensorStore() -> CSSensorStore{
        return CSSensorStore.sharedInstance()
    }
    
    static func loginSenseService(senseService: CSSensorStore, completeHandler: ()->Void){
        senseService.sender.applicationKey = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o";
        do{
            try senseService.loginWithUser("Username", andPassword: "Password", completeHandler: completeHandler, failureHandler: {})
        }catch{
            print(error)
            XCTFail()
        }
    }
}