//
//  DataStorageEngine.swift
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 25/09/15.
//
//

import Foundation

enum DatabaseError: ErrorType{
    case SensorAlreadyExists
}

public class DataStorageEngine{

    /**
    * Create a new sensor in database and backend if it does not already exist. Throw exception if it already exists. If it has been created, return the object.
    * an object.
    * @param name The sensor name (e.g accelerometer)
    * @param dataType The data type of the sensor
    * @param options The sensor options
    * @return sensor object
    **/
    public func createSensor(source: String, name: String, dataType: String, sensorOptions: SensorOptions) throws -> Sensor?
    {
        var sensor: Sensor?
        do{
            sensor = Sensor( name: name, sensorOptions: sensorOptions, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, source: source, dataType: dataType, synced: false)
            try DatabaseHandler.insertSensor(sensor!)
            
        }catch RLMError.DuplicatedObjects{
            throw DatabaseError.SensorAlreadyExists
        }catch {
            NSLog("inserting sensor has failed")
        }
        return sensor
    }

    /**
    * Returns a specific sensor by name and the source it belongs to
    * @param source The name of the source
    * @param sensorName The name of the sensor
    **/
    public func getSensor(source: String, sensorName : String) -> Sensor?{
        var sensor : Sensor?
        do{
            sensor = try DatabaseHandler.getSensor(source, sensorName)
        } catch RLMError.ObjectNotFound{
            NSLog("Sensor does not exist in DB")
        } catch RLMError.DuplicatedObjects{
            NSLog("Sensor is duplicated in DB")
        } catch {
            NSLog("Unknown error")
        }
        return sensor
    }
    
    /**
    * Returns all the sensors connected to the given source
    * @return [Sensor] The sensors connected to the given source
    **/
    public func getSensors(source: String) -> [Sensor]{
        return DatabaseHandler.getSensors(source)
    }
    
    /**
    * Returns all the sources attached to the current user
    * @return [String] The sources attached to the current user
    **/
    public func getSources() -> [String]{
        return DatabaseHandler.getSources()
    }
}