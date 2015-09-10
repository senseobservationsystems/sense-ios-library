//
//  RealmDatapoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation

class RealmDatapoint: Object{
    dynamic var sensor = RealmSensor()
    var value 
    var date = Double()
    var synced
    
}