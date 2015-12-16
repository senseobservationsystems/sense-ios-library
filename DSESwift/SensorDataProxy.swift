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
    
    /**
    * Get all sensor profiles
    * Throws an exception when no sessionId is set or when the sessionId is not valid.
    * @return Returns an array with sensor profiles, structured like:
    *         [{sensor_name: string, data_type: JSON}, ...]
    */
    static func getSensorProfiles() throws -> JSON {
        let result = Just.get(self.getUrl() + "/sensor_profiles", headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return JSON(result.json!)
    }
    
    /**
    * Get all sensors of the current source of logged in user
    * Throws an exception when no sessionId is set or when the sessionId is not valid.
    * @param sourceName     The source name. When no sourceName parameter is given, it returns all the sensors of the currrent logged in user. for example "sense-ios", "sense-android", "fitbit", ...
    * @return Returns an array containing sensors
    * 
    *
    */
    static func getSensors(sourceName: String? = nil) throws -> JSON {
        let result = Just.get(getSensorUrl(sourceName), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return JSON(result.json!)
    }
    
    /**
    * Get a sensor of the currently logged in user by it's source name
    * and sensor name.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @return Returns a Dictionary containing the sensor info
    */
    static func getSensor(sourceName: String, _ sensorName: String) throws -> JSON {
        let result = Just.get(getSensorUrl(sourceName, sensorName), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return JSON(result.json!)
    }
    
    /**
    * Update a sensors `meta` object. Will override the old `meta` object.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param meta           JSON object with meta data
    * @return               Returns a Dictionary containing the sensor info
    */
    static func updateSensor(sourceName sourceName: String, sensorName: String, meta: Dictionary<String, AnyObject>) throws -> JSON {
        let body = ["meta": meta]
        let result = Just.put(getSensorUrl(sourceName, sensorName), headers: getHeaders(), json: body);
        if let error = checkStatusCode(result.statusCode, successfulCode: 201){
            throw error
        }
        return JSON(result.json!)
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
    static func deleteSensor(sourceName: String, _ sensorName: String) throws {
        let result = Just.delete(getSensorUrl(sourceName, sensorName), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 204){
            throw error
        }
    }
    
    /**
    * Get sensor data.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, when
    * the sensor does not exist, or when the queryOptions are invalid.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param queryOptions   Query options to set start and end time, and to sort and limit the data
    * @return Returns a dictionary structured as:
    *  `{
    *    "sensor_name": String,
    *    "source_name": String,
    *    "meta": JSON
    *    "data":[{time: long, value: JSON}, ...]
    *   }`
    */
    static func getSensorData(sourceName sourceName: String, sensorName: String, var queryOptions: QueryOptions? = nil) throws -> JSON {
        if (!isValidQueryOptions(queryOptions)){ throw DSEError.InvalidQuery }
        
        if (queryOptions == nil) {
            queryOptions = QueryOptions()
        }  
        let result = Just.get(getSensorDataUrl(sourceName, sensorName), params: try queryOptions!.toQueryParams(), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return JSON(result.json!)
    }
    
    /**
    * Create or update sensor data for a single sensor.
    * Throws an exception when no sessionId is set, when the sessionId is not valid, or when
    * the sensor does not exist, or when the data contains invalid entries.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param data           Array with data points, structured as `[{time: long, value: JSON}, ...]`
    * @param meta           Dictionary for optional field to store meta information. Can be left null
    */
    static func putSensorData(sourceName sourceName: String, sensorName: String, data: JSON, meta: Dictionary<String, AnyObject>? = nil) throws {
        // create one sensor data object and create an array
        let sensorDataObject = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data, meta: meta);
        let sensorDataArray = [sensorDataObject]
        
        // construct body in JSONArray format
        let body = try JSONUtils.jsonToData(JSON(sensorDataArray))
        
        // send put request
        let result = Just.put(getSensorDataUrl(), headers: getHeadersWithContentType(), requestBody: body)
        if let error = checkStatusCode(result.statusCode, successfulCode: 201){
            throw error
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
    *                          "source_name": string,
    *                          "sensor_name", string,
    *                          "meta": JSON,   // optional
    *                          "data": [
    *                            {time: number, value: JSON},
    *                            // ...
    *                          ]
    *                        },
    *                        // ...
    *                      ]
    */
    static func putSensorData(sensorDataArray: JSON) throws {
        // construct body in JSONArray format
        let body = try JSONUtils.jsonToData(sensorDataArray)
        
        // send put request
        let result = Just.put(getSensorDataUrl(), headers: getHeadersWithContentType(), requestBody: body)
        if let error = checkStatusCode(result.statusCode, successfulCode: 201){
            throw error
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
    static func deleteSensorData(sourceName sourceName: String, sensorName: String, startTime: NSDate? = nil, endTime: NSDate? = nil) throws {
        if (!isStartTimeEarlierThanEndTime(startTime, endTime)){ throw DSEError.InvalidQuery }
        
        var params = Dictionary<String, AnyObject>()
        if startTime != nil { params["start_time"] = Int(startTime!.timeIntervalSince1970*1000)}
        if endTime != nil { params["end_time"] = Int(endTime!.timeIntervalSince1970)*1000}
        let result = Just.delete(getSensorDataUrl(sourceName, sensorName), params: params, headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 204){
            throw error
        }
    }
    
 
    // MARK: Helper functions
    
    /**
    * Helper function to create a JSONObject with the following structure:
    *
    *     {
    *       source_name: string,
    *       sensor_name, string,
    *       data: [
    *         {time: number, value: JSON},
    *         ...
    *       ]
    *     }
    *
    * This helper function can be used to prepare the data for putSensorData.
    * @param sourceName     The source name, for example "sense-ios",
    *                       "sense-android", "fitbit", ...
    * @param sensorName     The sensor name, for example "accelerometer"
    * @param data           Array with data points, structured as `[{time: long, value: JSON}, ...]`
    * @param meta           Optional field to store meta information. Can be left null
    */
    static func createSensorDataObject (sourceName sourceName: String, sensorName: String, data: JSON, meta: Dictionary<String, AnyObject>? = nil) -> JSON {
        var sensorData = Dictionary<String, AnyObject>()
        sensorData["source_name"] = sourceName;
        sensorData["sensor_name"] = sensorName;
        if (meta != nil) {
            sensorData["meta"] = meta!
        }
        var json = JSON(sensorData)
        json["data"] = data;
        
        return json;
    }
    
//    /**
//    * Returns NSData containing JSONArray. It perform JSONSerizlization on the given Array.
//    * Don't forget to validate the Array by calling NSJSONSerialization.isValidJSONObject before using this method.
//    */
//    private static func serializeArrayToJSONArray(sensorsData: JSON) throws -> NSData{
//        //let body = try NSJSONSerialization.dataWithJSONObject(sensorsData, options: NSJSONWritingOptions(rawValue: 0))
//        let body = try JSONUtils.jsonToData(sensorsData)
//        return body
//    }
    
    private static func getSensorUrl(sourceName: String? = nil, _ sensorName: String? = nil) -> String{
        let url = self.getUrl() + "/sensors"
        return addAppendixToURL(url, sourceName: sourceName, sensorName: sensorName)
    }
    
    private static func getSensorDataUrl(sourceName: String? = nil, _ sensorName: String? = nil) -> String{
        let url = self.getUrl() + "/sensor_data"
        return addAppendixToURL(url, sourceName: sourceName, sensorName: sensorName)
    }
    
    private static func addAppendixToURL(var url: String, sourceName: String?, sensorName: String?) -> String{
        if(sourceName != nil){ url = url + "/" + sourceName!}
        if(sensorName != nil){ url = url + "/" + sensorName!}
        return url
    }
    
    private static func getHeadersWithContentType() -> [String: String]{
        var headers = self.getHeaders()
        headers["CONTENT-TYPE"] = "application/json"
        return headers
    }
    
    private static func getHeaders() -> [String: String]{
        let headers = ["APPLICATION-KEY": self.getAppKey(), "SESSION-ID": self.getSessionId()]
        return headers
    }
    
    private static func isValidQueryOptions(queryOptions: QueryOptions?) -> Bool{
        if (queryOptions == nil){
            return true
        }
        
        let isValidStartEndTimes = isStartTimeEarlierThanEndTime(queryOptions!.startTime, queryOptions!.endTime)
        let isValidLimit = (queryOptions!.limit != nil) ? queryOptions!.limit > 0 : true
        
        return isValidStartEndTimes && isValidLimit
    }
    
    private static func isStartTimeEarlierThanEndTime(startTime: NSDate?, _ endTime: NSDate?) -> Bool{
        // check if both of start and end is pupulated
        if startTime == nil || endTime == nil {
            return true
        }
        // is startDate ealier
        if startTime!.timeIntervalSinceReferenceDate < endTime!.timeIntervalSinceReferenceDate {
            return true
        } else {
            return false
        }
    }
    
    private static func checkStatusCode(statusCode: Int?, successfulCode: Int) -> DSEError?{
        if (statusCode == 401){
            return DSEError.InvalidSessionId
        } else if (statusCode == 400){
            return DSEError.InvalidSensorOrSourceOrBadStructure //Bad structure too
        } else if (statusCode == 404){
            return DSEError.SensorDoesNotExist
        } else if (statusCode != successfulCode) || (statusCode == nil){
            return DSEError.UnknownError
        }
        return nil
    }
    
    private static func getUrl() -> String {
        let BASE_URL_LIVE = "https://sensor-api.sense-os.nl";
        let BASE_URL_STAGING = "http://sensor-api.staging.sense-os.nl";
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let serverString = defaults.stringForKey(DSEConstants.BACKEND_ENVIRONMENT_KEY);
        return (serverString == "LIVE") ? BASE_URL_LIVE : BASE_URL_STAGING;
    }
    
    private static func getAppKey() -> String {
        let defaults = NSUserDefaults.standardUserDefaults()
        return defaults.stringForKey(DSEConstants.APPKEY_KEY)!
    }
    
    private static func getSessionId() -> String {
        return KeychainWrapper.stringForKey(DSEConstants.KEYCHAIN_SESSIONID)!
    }
    
}
