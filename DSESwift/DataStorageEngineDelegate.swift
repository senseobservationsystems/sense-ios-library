//
//  DataStorageEngineDelegate.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 29/10/15.
//
//

import Foundation

/**
 * The DataStorageEngineDelegate interface/protocol defines the methods used to receive updates from a DataStorageEngine.
 */
public protocol DataStorageEngineDelegate{

    /**
     * Callback method called on the completion of downloading sensor profiles.
     **/
    func onSensorProfilesDownloaded()
    
    /**
     * Callback method on the completion of downloading Sensors from Remote.
     *
     * @param: An array of sensors that are downloaded from Remote.
     **/
    func onSensorsDownloaded(sensors: Array<Sensor>)
}