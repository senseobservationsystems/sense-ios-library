//
//  RealmSensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation

class RealmSensor: Object{
    dynamic var id
    dynamic var name
    dynamic var meta
    dynamic var flag_cs_upload
    dynamic var flag_cs_download
    dynamic var flag_persist_locally
    dynamic var user = RealmUser()
    dynamic var source_id = RealmSource()
    dynamic var data_type
    dynamic var cs_id
}