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

    dynamic var synced = true
    dynamic var value = ""
    dynamic var sensorId: Int = -1
    dynamic var date = 0.0
    dynamic lazy var id: String = self.getId()
    
    /*
     * This method can be called if the sensorId or the date have changed after the id has been used.
     */
    func updateId() {
        self.id = self.getId()
    }

    override static func primaryKey() -> String? {
        return "id"
    }
    
    private func getId() -> String {
        return "\(self.sensorId)-\(String(self.date))"
    }
    
}