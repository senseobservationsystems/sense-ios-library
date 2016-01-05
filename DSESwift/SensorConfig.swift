//
//  SensorConfig.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

@objc public class SensorConfig: NSObject{
    public var meta: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()  // null by default, if not null, change from default
    public var uploadEnabled: Bool = false// null by default, if not null, change from default
    public var downloadEnabled: Bool = false// null by default, if not null, change from default
    public var persist: Bool = false// null by default, if not null, change from default
    
}

