//
//  RealmDatapoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import Realm

class RLMDatapoint: Object{
    dynamic var sensor = RealmSensor()
    var value 
    var date = Double()
    var synced
    
}