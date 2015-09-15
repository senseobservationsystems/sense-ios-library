//
//  RealmSource.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMSource: Object{
    dynamic var id = "1"
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var uuid = ""
    dynamic var cs_id = ""

    override static func primaryKey() -> String? {
        return "id"
    }
    
    func getNextKey() -> String{
        let realm = try! Realm()
        let result = realm.objects(RLMSource)
        return String(result.count+1)
    }
}