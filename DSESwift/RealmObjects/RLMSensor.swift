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
    dynamic var id = -1
    dynamic var compoundKey = ""
    dynamic var name = ""
    dynamic var meta = ""
    dynamic var remoteUploadEnabled = true
    dynamic var remoteDownloadEnabled = true
    dynamic var persistLocally = true
    dynamic var userId = ""
    dynamic var source = ""
    dynamic var remoteDataPointsDownloaded = false

    /*
    * This method has to be called when the sensorId or the date is set.
    */
    func updateId() {
        self.compoundKey = self.getCompoundKey()
    }
    
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    
    private func getCompoundKey() -> String {
        return "\(self.name):\(self.source):\(self.userId)"
    }
    
}