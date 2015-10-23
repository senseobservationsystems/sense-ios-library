//
//  SensorDataProxy.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 15/10/15.
//
//

import Foundation
import Just

public class SensorDataProxy {
    
    public enum Server {
        case LIVE
        case STAGING
    }
    
    public enum ProxyError: ErrorType, Equatable{
        case SessionIdNotSet
        case InvalidSessionId
        case InvalidSensorOrSource //thrown when invalid sensorName/sourceName is given
        case InvalidDataFormat
        case InvalidQuery
        case SensorDoesNotExistOrBadStructure
        case UnknownError
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
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        let result = Just.get(self.baseUrl! + "/sensor_profiles", headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return result.json as? Array<AnyObject>
    }
    

    
    /**
    * Get all sensors of the current source of logged in user
    * Throws an exception when no sessionId is set or when the sessionId is not valid.
    * @param sourceName     The source name. When no sourceName parameter is given, it returns all the sensors of the currrent logged in user. for example "sense-ios", "sense-android", "fitbit", ...
    * @return Returns a json containing sensors
    */
    func getSensors(sourceName: String? = nil) throws -> Array<AnyObject>?{
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        let result = Just.get(getSensorUrl(sourceName), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
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
    * @return Returns a Dictionary containing the sensor info
    */
    func getSensor(sourceName: String, _ sensorName: String) throws -> Dictionary<String, AnyObject>?{
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        let result = Just.get(getSensorUrl(sourceName, sensorName), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
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
    * @return               Returns a Dictionary containing the sensor info
    */
    func updateSensor(sourceName sourceName: String, sensorName: String, meta: Dictionary<String, AnyObject>) throws -> Dictionary<String, AnyObject>? {
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        let body = ["meta": meta]
        let result = Just.put(getSensorUrl(sourceName, sensorName), headers: getHeaders(), json: body);
        if let error = checkStatusCode(result.statusCode, successfulCode: 201){
            throw error
        }
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
    func deleteSensor(sourceName: String, _ sensorName: String) throws {
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
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
    * @return Returns an Dictionary containing the sensor data, where the data is structured as `[{date: long, value: JSON}, ...]`
    */
    func getSensorData(sourceName sourceName: String, sensorName: String, var queryOptions: QueryOptions? = nil) throws -> Dictionary<String, AnyObject>?{
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        if (!isValidQueryOptions(queryOptions)){ throw ProxyError.InvalidQuery }
        
        if (queryOptions == nil) {
            queryOptions = QueryOptions()
        }  
        let result = Just.get(getSensorDataUrl(sourceName, sensorName), params: try queryOptions!.toQueryParams(), headers: getHeaders())
        if let error = checkStatusCode(result.statusCode, successfulCode: 200){
            throw error
        }
        return result.json as? Dictionary<String, AnyObject>
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
    func putSensorData(sourceName sourceName: String, sensorName: String, data: Array<AnyObject>, meta: Dictionary<String, AnyObject>? = nil) throws {
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        // create one sensor data object and create an array
        let sensorDataObject = SensorDataProxy.createSensorDataObject(sourceName: sourceName, sensorName: sensorName, data: data);
        let sensorDataArray = [sensorDataObject]
        
        // construct body in JSONArray format
        let body = try serializeArrayToJSONArray(sensorDataArray)
        
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
    func putSensorData(sensorDataArray: Array<AnyObject>) throws {
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        
        // construct body in JSONArray format
        let body = try serializeArrayToJSONArray(sensorDataArray)
        
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
    func deleteSensorData(sourceName sourceName: String, sensorName: String, startDate: NSDate? = nil, endDate: NSDate? = nil) throws {
        if (!isSessionIdSet()){ throw ProxyError.SessionIdNotSet }
        if (!isStartDateEarlierThanEndDate(startDate, endDate)){ throw ProxyError.InvalidQuery }
        
        var params = Dictionary<String, AnyObject>()
        if startDate != nil { params["start_time"] = Int(startDate!.timeIntervalSince1970*1000)}
        if endDate != nil { params["end_time"] = Int(endDate!.timeIntervalSince1970)*1000}
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
    
    /**
    * Returns NSData containing JSONArray. It perform JSONSerizlization on the give Array.
    * Don't forget to validate the Array by calling NSJSONSerialization.isValidJSONObject before using this method.
    */
    private func serializeArrayToJSONArray(sensorsData: Array<AnyObject>) throws -> NSData?{
        let body = try NSJSONSerialization.dataWithJSONObject(sensorsData, options: NSJSONWritingOptions(rawValue: 0))
        return body
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
    
    private func getHeadersWithContentType() -> [String: String]{
        var headers = getHeaders()
        headers["CONTENT-TYPE"] = "application/json"
        return headers
    }
    
    private func getHeaders() -> [String: String]{
        let headers = ["APPLICATION-KEY": self.appKey!,
            "SESSION-ID": self.sessionId!]
        return headers
    }
    
    private func isSessionIdSet() -> Bool{
        return (self.sessionId != nil)
    }
    
    private func isValidQueryOptions(queryOptions: QueryOptions?) -> Bool{
        if (queryOptions == nil){
            return true
        }
        
        let isValidStartEndDates = isStartDateEarlierThanEndDate(queryOptions!.startDate, queryOptions!.endDate)
        let isValidLimit = (queryOptions!.limit != nil) ? queryOptions!.limit > 0 : true
        
        return isValidStartEndDates && isValidLimit
    }
    
    private func isStartDateEarlierThanEndDate(startDate: NSDate?, _ endDate: NSDate?) -> Bool{
        // check if both of start and end is pupulated
        if startDate == nil || endDate == nil {
            return true
        }
        // is startDate ealier
        if startDate!.timeIntervalSinceReferenceDate < endDate!.timeIntervalSinceReferenceDate {
            return true
        } else {
            return false
        }
    }
    
    private func checkStatusCode(statusCode: Int?, successfulCode: Int) -> ProxyError?{
        if (statusCode == 401){
            return ProxyError.InvalidSessionId
        } else if (statusCode == 400){
            return ProxyError.InvalidSensorOrSource //Bad structure too
        } else if (statusCode == 404){
            return ProxyError.SensorDoesNotExistOrBadStructure
        } else if (statusCode != successfulCode) || (statusCode == nil){
            return ProxyError.UnknownError
        }
        return nil
    }
    
}
