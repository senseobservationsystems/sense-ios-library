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
    * Get all sensor profiles
    * Throws an exception when no sessionId is set or when the sessionId is not valid.
    * @return Returns an array with sensor profiles, structured like:
    *         [{sensor_name: string, data_type: JSON}, ...]
    */
    func getSensorProfiles() throws -> Array<AnyObject>?{
        let result = Just.get(self.baseUrl! + "/sensor_profiles", headers: getHeaders())
        if (result.error != nil){
            print(result.error)
            throw ProxyError.SomethingWentWrong
        }
        return result.json as? Array<AnyObject>
    }
    
    /**
     * Get all sensors of the currently logged in user
     * Throws an exception when no sessionId is set or when the sessionId is not valid.
     * @return Returns a json containing sensors
    */
    func getSensors() throws -> Array<AnyObject>?{
        let result = Just.get(getSensorUrl(), headers: getHeaders())
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
        let result = Just.get(getSensorUrl(sourceName), headers: getHeaders())
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
    func getSensor(sourceName: String, _ sensorName: String) throws -> Dictionary<String, AnyObject>?{
        let result = Just.get(getSensorUrl(sourceName, sensorName), headers: getHeaders())
        if (result.error != nil){
            print(result.error)
            throw ProxyError.SomethingWentWrong
        }
        return result.json as? Dictionary<String, AnyObject>
    }
    
    /**
    * Update a sensors `meta` object. Will override the old `meta` object.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param meta           JSON object with meta data
    * @return               Returns the sensor object
    */
    func updateSensor(sourceName sourceName: String, sensorName: String, meta: Dictionary<String, AnyObject>) throws -> Dictionary<String, AnyObject>? {
        let body = ["meta": meta]
        let result = Just.put(getSensorUrl(sourceName, sensorName), headers: getHeaders(), json: body);
        return result.json as? Dictionary<String, AnyObject>
    }
    
    /**
    * Delete a sensor including all its data
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist.
    *
    * WARNING: this is a dangerous method! Use with care. Or better: don't use it at all.
    *
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    */
    func deleteSensor(sourceName: String, _ sensorName: String){
        Just.delete(getSensorUrl(sourceName, sensorName), headers: getHeaders())
    }
    
    /**
    * Get sensor data.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, when
    * the sensor does not exist, or when the queryOptions are invalid.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param queryOptions   Query options to set start and end time, and to sort and limit the data
    * @return Returns an Array containing the sensor data, structured as `[{date: long, value: JSON}, ...]`
    */
    func getSensorData(sourceName sourceName: String, sensorName: String, var queryOptions: QueryOptions? = nil) -> Dictionary<String, AnyObject>?{
        
        var dict : Dictionary<String, AnyObject>?
        if (queryOptions == nil) { queryOptions = QueryOptions()}
        do{
            let result = Just.get(getSensorDataUrl(sourceName, sensorName), headers: getHeaders())
            let json = try NSJSONSerialization.JSONObjectWithData(result.content!, options: NSJSONReadingOptions(rawValue: 0))
            dict = json as? Dictionary<String, AnyObject>
        }catch{
            print(error)
        }
        return dict!
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
    func putSensorData(sourceName sourceName: String, sensorName: String, data: Array<AnyObject>, meta: Dictionary<String, AnyObject>? = nil) {
        // create one sensor data object
        let sensorDataObject = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
        let jsonArray = [sensorDataObject]
        do{
            let body = try NSJSONSerialization.dataWithJSONObject(jsonArray, options: NSJSONWritingOptions(rawValue: 0))
            var header = getHeaders()
            header["CONTENT-TYPE"] = "application/json"
            Just.put(getSensorDataUrl(), headers: header, requestBody: body)
        }catch{
            NSLog("error")
        }
    }
    
    /**
    * Create or update a sensor data of multiple sensors at once.
    *
    * The helper function `createSensorDataObject` can be used to build the JSONObjects for
    * each sensor.
    *
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist, or when the data contains invalid entries.
    * @param sensorsData   Array with sensor data of multiple sensors, structured as:
    *
    *                      [
    *                        {
    *                          source_name: string,
    *                          sensor_name, string,
    *                          meta: JSON,   // optional
    *                          data: [
    *                            {date: number, value: JSON},
    *                            // ...
    *                          ]
    *                        },
    *                        // ...
    *                      ]
    */
    func putSensorData(sensorsData: Array<AnyObject>) {
        // create one sensor data object
        do{
            let body = try NSJSONSerialization.dataWithJSONObject(sensorsData, options: NSJSONWritingOptions(rawValue: 0))
            var header = getHeaders()
            header["CONTENT-TYPE"] = "application/json"
            Just.put(getSensorDataUrl(), headers: header, requestBody: body)
        }catch{
            NSLog("error")
        }
    }
    
    /**
    * Delete sensor data.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, when
    * the sensor does not exist, or when startTime or endTime are invalid.
    *
    * WARNING: this is a dangerous method, use with care.
    *
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer".
    * @param startTime      Start time of the data series to be deleted.
    *                       When startTime is null, all data until endTime will be removed.
    * @param endTime        End time of the data series to be deleted.
    *                       When endTime is null, all data from startTime till now will be removed.
    *                       When both startTime and endTime are null, all data will be removed.
    */
    func deleteSensorData(sourceName: String, sensorName: String, startDate: NSDate?, endDate: NSDate?){
        var params = Dictionary<String, AnyObject>()
        if startDate != nil { params["start_time"] = JSONUtils.stringify(startDate!.timeIntervalSince1970)}
        if endDate != nil { params["end_time"] = JSONUtils.stringify(endDate!.timeIntervalSince1970)}
        Just.delete(getSensorDataUrl(sourceName, sensorName), params: params, headers: getHeaders())
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
    static func createSensorDataObject (sourceName sourceName: String, sensorName: String, data: Array<AnyObject>, meta: Dictionary<String, AnyObject>? = nil) -> Dictionary<String, AnyObject> {
        var sensorData = Dictionary<String, AnyObject>()
        sensorData["source_name"] = sourceName;
        sensorData["sensor_name"] = sensorName;
        if (meta != nil) {
            sensorData["meta"] = meta!
        }
        sensorData["data"] = data;
        
        return sensorData;
    }
    
    private func getSensorUrl(sourceName: String? = nil, _ sensorName: String? = nil) -> String{
        let url = self.baseUrl! + "/sensors"
        return addAppendixToURL(url, sourceName: sourceName, sensorName: sensorName)
    }
    
    private func getSensorDataUrl(sourceName: String? = nil, _ sensorName: String? = nil) -> String{
        let url = self.baseUrl! + "/sensor_data"
        return addAppendixToURL(url, sourceName: sourceName, sensorName: sensorName)
    }
    
    private func addAppendixToURL(var url: String, sourceName: String?, sensorName: String?) -> String{
        if(sourceName != nil){ url = url + "/" + sourceName!}
        if(sensorName != nil){ url = url + "/" + sensorName!}
        return url
    }
    
    private func getHeaders() -> [String: String]{
        let headers = ["APPLICATION-KEY": self.appKey!,
            "SESSION-ID": self.sessionId!]
        return headers
    }
    
}
