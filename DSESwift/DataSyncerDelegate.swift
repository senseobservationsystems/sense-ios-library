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
    func onInitializationFailed(error: DSEError)
    
    func onSensorsDownloadCompleted()
    func onSensorsDownloadFailed(error: DSEError)
    
    func onSensorDataDownloadCompleted()
    func onSensorDataDownloadFailed(error: DSEError)
    
    func onException(error:DSEError)
}