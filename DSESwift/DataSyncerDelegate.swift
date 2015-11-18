//
//  DataSyncerDelegate.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 17/11/15.
//
//

import Foundation

protocol DataSyncerDelegate{

    func onInitializationCompleted()
    func onInitializationFailed(error: ErrorType)
    
    func onSensorsDownloadCompleted()
    func onSensorsDownloadFailed(error: ErrorType)
    
    func onSensorDataDownloadCompleted()
    func onSensorDataDownloadFailed(error: ErrorType)
    
    func onSyncCompleted()
    func onSyncFailed(error: ErrorType)
}