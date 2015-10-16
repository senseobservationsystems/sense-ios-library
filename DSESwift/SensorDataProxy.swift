//
//  SensorDataProxy.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 15/10/15.
//
//

import Foundation
import Just
import SwiftyJSON

public class SensorDataProxy {
    
    public enum Server {
        case LIVE
        case STAGING
    }
    
    enum ProxyError: ErrorType{
        case SomethingWentWrong
    }
    
    let BASE_URL_LIVE = "https://sensor-api.sense-os.nl";
    let BASE_URL_STAGING = "http://sensor-api.staging.sense-os.nl";
    
    var baseUrl: String?
    var appKey: String?
    var sessionId: String?
    
    
    /**
    * Create a sensor data proxy.
    * @param server     Select whether to use the live or staging server.
    * appKey     Application key, identifying the application in the REST API.
    * @param sessionId  The session id of the current user.
    */
    init (server: Server, appKey: String, sessionId: String) {
        self.baseUrl = (server == Server.LIVE) ? BASE_URL_LIVE : BASE_URL_STAGING;
        self.appKey = appKey;
        self.sessionId = sessionId;
    }
    
    func setSessionId(sessionId: String){
        self.sessionId = sessionId
    }
    
    /**
     * Get all sensors of the currently logged in user
     * Throws an exception when no sessionId is set or when the sessionId is not valid.
     * @return Returns a json containing sensors
    */
    func getSensors() throws -> Array<AnyObject>?{
        let result = Just.get(self.baseUrl! + "/sensors", headers: getHeader())
        if (result.error != nil){
            print(result.error)
            throw ProxyError.SomethingWentWrong
        }
        return result.json as? Array<AnyObject>
    }
    
    /**
    * Get all sensors of the current source of logged in user
    * Throws an exception when no sessionId is set or when the sessionId is not valid.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @return Returns a json containing sensors
    */
    func getSensors(sourceName: String) throws -> Array<AnyObject>?{
        let result = Just.get(self.baseUrl! + "/sensors" + sourceName, headers: getHeader())
        if (result.error != nil){
            print(result.error)
            throw ProxyError.SomethingWentWrong
        }
        return result.json as? Array<AnyObject>
    }
    
    /**
    * Get a sensor of the currently logged in user by it's source name
    * and sensor name.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @return Returns a json containing the sensor
    */
    func getSensors(sourceName: String, sensorName: String) throws -> Array<AnyObject>?{
        let result = Just.get(self.baseUrl! + "/sensors/" + sourceName + "/" + sensorName, headers: getHeader())
        if (result.error != nil){
            print(result.error)
            throw ProxyError.SomethingWentWrong
        }
        return result.json as? Array<AnyObject>
    }
    
    
    
    
    /**
    * Create or update sensor data for a single sensor.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist, or when the data contains invalid entries.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param data           Array with data points, structured as `[{date: long, value: JSON}, ...]`
    * @param meta           Dictionary for optional field to store meta information. Can be left null
    */
    func putSensorData(sourceName sourceName: String, sensorName: String, data: Array<AnyObject>, meta: Dictionary<String, AnyObject>?) {
        // create one sensor data object
        let sensorDataObject = SensorDataProxy.createSensorDataObject(sourceName, sensorName: sensorName, data: data, meta: meta);
        Just.put(self.baseUrl! + "/sensors/" + sourceName + "/" + sensorName, params: getHeader(), headers: getHeader(), json: sensorDataObject)
    }
    
 
    // MARK: Helper functions
    
    /**
    * Helper function to create a JSONObject with the following structure:
    *
    *     {
    *       source_name: string,
    *       sensor_name, string,
    *       data: [
    *         {date: number, value: JSON},
    *         ...
    *       ]
    *     }
    *
    * This helper function can be used to prepare the data for putSensorData.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param data           Array with data points, structured as `[{date: long, value: JSON}, ...]`
    * @param meta           Optional field to store meta information. Can be left null
    */
    static func createSensorDataObject (sourceName: String, sensorName: String, data: Array<AnyObject>, meta: Dictionary<String, AnyObject>?) -> Dictionary<String, AnyObject>? {
        var sensorData = Dictionary<String, AnyObject>()
        sensorData["source_name"] = sourceName;
        sensorData["sensor_name"] = sensorName;
        if (meta != nil) {
            sensorData["meta"] = meta!
        }
        sensorData["data"] = data;
        
        return sensorData;
    }
    
    func test(){
        let result = Just.get("http://jsonplaceholder.typicode.com/posts/1")
        let json = JSON(result.json!)
        debugPrint(json["title"])
    }
    
    
    private func getHeader() -> [String: String]{
        let headers = ["APPLICATION-KEY": self.appKey!,
            "SESSION-ID": self.sessionId!]
        return headers
    }
    
}
