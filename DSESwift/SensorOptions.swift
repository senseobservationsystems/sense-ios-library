//
//  SensorOptions.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 11/09/15.
//
//

import Foundation

public class SensorOptions{
    var meta = "" // null by default, if not null, change from default
    var uploadEnabled: Bool // null by default, if not null, change from default
    var downloadEnabled: Bool // null by default, if not null, change from default
    var persist: Bool // null by default, if not null, change from default
    
    public init(meta:String, uploadEnabled: Bool, downloadEnabled: Bool, persist: Bool) {
        self.meta = meta
        self.uploadEnabled = uploadEnabled
        self.downloadEnabled = downloadEnabled
        self.persist = persist
    }
    
    public convenience init() {
        self.init(meta: "", uploadEnabled: true, downloadEnabled: true, persist: true)
    }
}