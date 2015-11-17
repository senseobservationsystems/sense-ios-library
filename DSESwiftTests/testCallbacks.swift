//
//  testCallbacks.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/11/15.
//
//

import Foundation
@testable import DSESwift

class OnReadyCallback: DSEAsyncCallback{
    
    func onSuccess() {
        print("Yay success!")
    }
    
    func onFailure() throws {
        print("Failure!")
    }
}

class OnSensorDownloadedCallback: DSEAsyncCallback{
    
    func onSuccess() {
        print("Yay success!")
    }
    
    func onFailure() throws {
        print("Failure!")
    }
}

class OnSensorDataDownloadedCallback: DSEAsyncCallback{
    
    func onSuccess() {
        print("Yay success!")
    }
    
    func onFailure() throws {
        print("Failure!")
    }
}