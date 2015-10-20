//
//  MockProxy.swift
//  SensePlatform
//
//  Created by Fei on 15/10/15.
//
//

import Foundation
class MockProxy: NSObject {

    class func getSensorProfile() {}
    
    class func deleteSensorData(sourceName: String, sensorName: String, startTime:  Double, endTime: Double) {}
    
    class func getSensors(source: String) -> [NSArray] { return  [NSArray]() }
    
    class func getSensorData(sourceName: String, sensorName: String, queryOptions: QueryOptions) -> [NSArray] { return [NSArray]() }
    
    class func putSensorData(sourceName: String, sensorName: String, dataArray: NSMutableArray, meta: String) {}
}
