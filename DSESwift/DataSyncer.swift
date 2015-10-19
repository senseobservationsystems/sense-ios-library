//
//  DataSyncer.swift
//  SensePlatform
//
//  Created by Fei on 15/10/15.
//
//

import Foundation
import RealmSwift

class DataSyncer: NSObject {

    func login() {
    downloadSensorProfile ()
    }
    
    func synchronize() {
        self.deletionInRemote ()
        self.downloadFromRemote ()
        self.uploadToRemote ()
        self.cleanUpLocalStorage ()
    }
    
    func enablePeriodicSync() {}
    func disablePeriodicSync(){}
    
    func downloadSensorProfile() {
        MockProxy.getSensorProfile()
        
//closure 语法
//        (parameters) -> returnType in
//        
//        statements
    }
    func deletionInRemote() {
        
    }
    func downloadFromRemote() {}
    func uploadToRemote() {}
    func cleanUpLocalStorage() {}
    
    
}