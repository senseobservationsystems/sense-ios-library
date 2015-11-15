//
//  TestUtil.swift
//  SensePlatform
//
//  Created by Alex on 11/13/15.
//
//

import Foundation
@testable import DSESwift

public func getAppKeyAndSessionId() {
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    let accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
    let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
    accountUtils.registerUser(username, password: "Password")
    accountUtils.loginUser(username, password: "Password")
}

// MARK: == helper functions
// @param time: the datapoints will have time.timeIntervalSince1970 + index
func getDummyAccelerometerData(var time time: NSDate? = nil) -> Array<AnyObject>{
    if time == nil {
        time = NSDate().dateByAddingTimeInterval(-60)
    }
    let value = ["x-axis": 4, "y-axis": 5, "z-axis": 6]
    var data = Array<AnyObject>()
    //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
    for (var i :Double = 0 ; i < 5 ; i++) {
        let dataPoint = ["time": (Int((time!.timeIntervalSince1970 + i) * 1000)), "value": value]
        data.append(dataPoint)
    }
    return data
}

// @param time: the datapoints will have time.timeIntervalSince1970 + index
func getDummyTimeActiveData(var time time: NSDate? = nil) -> Array<AnyObject>{
    if time == nil {
        time = NSDate().dateByAddingTimeInterval(-60)
    }
    
    let value = 3
    var data = Array<AnyObject>()
    //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
    for (var i :Double = 0 ; i < 5 ; i++) {
        let dataPoint = ["time": Int((time!.timeIntervalSince1970 + i)  * 1000), "value": value]
        data.append(dataPoint)
    }
    return data
}

func getDummyDataWithBadStructure() -> Array<AnyObject>{
    let time = NSDate().dateByAddingTimeInterval(-60)
    let value = ["invalidx": 4, "invalidy": 5, "invalidz": 6]
    var data = Array<AnyObject>()
    //TODO: increase the ceiling to 100 when the backend issue about slow insertion is resolved
    for (var i :Double = 0 ; i < 5 ; i++) {
        let dataPoint = ["time": Double((time.timeIntervalSince1970 + i) * 1000.0), "value": value]
        data.append(dataPoint)
    }
    return data
}