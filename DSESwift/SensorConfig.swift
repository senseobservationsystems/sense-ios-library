//
//  SensorConfig.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public struct SensorConfig{
    var meta : Dictionary<String, AnyObject>? = nil  // null by default, if not null, change from default
    var uploadEnabled: Bool? = true// null by default, if not null, change from default
    var downloadEnabled: Bool? = true// null by default, if not null, change from default
    var persist: Bool? = true// null by default, if not null, change from default
}