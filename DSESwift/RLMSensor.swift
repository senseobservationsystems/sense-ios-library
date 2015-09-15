//
//  RealmSensor.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMSensor: Object{
    dynamic var id = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var cs_upload_enabled = true
    dynamic var cs_download_enabled = true
    dynamic var persist_locally = true
    dynamic var userId = ""
    dynamic var sourceId = ""
    dynamic var data_type = ""
    dynamic var cs_id = ""
    dynamic var synced = false

    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getNextKey() -> String{
        let realm = try! Realm()
        let result = realm.objects(RLMSensor)
        return String(result.count+1)
    }
}