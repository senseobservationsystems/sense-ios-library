//
//  TestUtil.swift
//  SensePlatform
//
//  Created by Alex on 11/13/15.
//
//

import Foundation
@testable import DSESwift

public func getAppKeyAndSessionId() {
    let APPKEY_STAGING = "o4cbgFZjPPDA6GO32WipJBLnyazu8w4o"
    let accountUtils = CSAccountUtils(appKey: APPKEY_STAGING)
    let username = String(format:"spam+%f@sense-os.nl", NSDate().timeIntervalSince1970)
    accountUtils.registerUser(username, password: "Password")
    accountUtils.loginUser(username, password: "Password")
}