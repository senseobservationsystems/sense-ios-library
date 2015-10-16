//
//  CSAccountUtils.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 16/10/15.
//
//

import Foundation
import Just
import SwiftyJSON
import DSESwift
import CryptoSwift

public class CSAccountUtils{
    
    public let BASE_URL_CS_STAGING = "http://api.staging.sense-os.nl";
    public let BASE_URL_AUTHENTICATION_STAGING = "http://auth-api.staging.sense-os.nl/v1";
    
    var baseUrl: String?
    var appKey: String?
    var sessionId: String?
    
    /**
    * Create a sensor data proxy.
    * @param server     Select whether to use the live or staging server.
    * appKey     Application key, identifying the application in the REST API.
    * @param sessionId  The session id of the current user.
    */
    init (appKey: String) {
        self.baseUrl = BASE_URL_CS_STAGING;
        self.appKey = appKey;
    }
    
    func testPOST(){
        let r = Just.post("http://httpbin.org/post")
        debugPrint(r)
    }
    
    func registerUser(username: String, password: String) -> Bool{
        var didSucceed = true
        let registrationUrl = self.baseUrl! + "/users"
        let headers = ["APPLICATION-KEY": self.appKey!]
        let body = ["user":["username": username, "email": username , "password": password.md5()]]
        // send request
        let r = Just.post(registrationUrl, headers: headers, json: body)
        // evaluate the response
        if(!r.ok){
            didSucceed = false
            NSLog("Couldn't register user.");
            //NSLog("Responded: %s", JSON(r.json!).string!);
        }
        return didSucceed
    }
    
    func loginUser(username: String, password: String) {
        let registrationUrl = BASE_URL_AUTHENTICATION_STAGING + "/login"
        let headers = ["APPLICATION-KEY": self.appKey!]
        let body = ["username": username, "password": password.md5()]
        // send request
        let r = Just.post(registrationUrl, headers: headers, json: body)
        // evaluate the response
        let responseJson = JSON(r.json!)
        self.sessionId = responseJson["session_id"].string!
    }
    
    func deleteUser() -> Bool{
        var didSucceed = true
        let registrationUrl = self.baseUrl! + "/users"
        let parameters = ["APPLICATION-KEY": self.appKey!, "SESSION-ID": self.sessionId!]
        let response = Just.delete(registrationUrl, params: parameters)
        // evaluate the response
        if(response.statusCode != 200){
            didSucceed = false
            NSLog("Couldn't delete user.");
            NSLog("Responded: %s", response.text!);
        }
        return didSucceed
    }
    
    
}