//
//  RealmDatapoint.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 09/09/15.
//
//

import Foundation
import RealmSwift

class RLMDataPoint: Object{

    dynamic var value = ""
    dynamic var sensorId: Int = -1
    dynamic var time = 0.0
    dynamic var id: String = ""
    dynamic var existsInRemote = false
    
    /*
     * This method has to be called when the sensorId or the date is set.
     */
    func updateId() {
        self.id = self.getId()
    }

    override static func primaryKey() -> String? {
        return "id"
    }
    
    private func getId() -> String {
        return "\(self.sensorId):\(String(self.time))"
    }
    
}