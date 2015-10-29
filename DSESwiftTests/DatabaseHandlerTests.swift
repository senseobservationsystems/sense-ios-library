//
//  DSESwiftTests.swift
//  DSESwiftTests
//
//  Created by Alex on 9/9/15.
//
//

import XCTest
import RealmSwift


@testable import DSESwift


class DatabaseHandlerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        Realm.Configuration.defaultConfiguration.inMemoryIdentifier = "test"
        KeychainWrapper.setString("user1", forKey: KEYCHAIN_USERID)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testInsertDataPoint() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(100)
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetDataPointWithValidLimit() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            for (var i=0; i < 101; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(100)
            queryOptions.limit = 80
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 80)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetDataPointWithEmptyStartAndEnd() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName,  sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            // add 50 datapoints with date of 3 years ago
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate().dateByAddingTimeInterval(-3*365*24*60*60))
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            // add 50 datapoints with date of recent time
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            let queryOptions = QueryOptions()
            
            let dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 100)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteDataPointWithEmptyStartAndEnd() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            // add 50 datapoints with date of 3 years ago
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate().dateByAddingTimeInterval(-3*365*24*60*60))
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            // add 50 datapoints with date of recent time
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            let queryOptions = QueryOptions()
            
            var dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 100)
            
            let deleteOptions = QueryOptions()
            
            try DatabaseHandler.deleteDataPoints(sensor.id, deleteOptions)
            
            dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 0)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteDataPointWithEnd() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint: DataPoint!
            // add 50 datapoints with date of 3 years ago
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate().dateByAddingTimeInterval(-3*365*24*60*60))
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            // add 50 datapoints with date of recent time
            for (var i=0; i < 50; i++){
                dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
                try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            }
            
            let queryOptions = QueryOptions()
            
            var dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 100)
            
            var deleteOptions = QueryOptions()
            deleteOptions.endTime = NSDate().dateByAddingTimeInterval(-1*365*24*60*60)
            
            //delete Data when it is old
            try DatabaseHandler.deleteDataPoints(sensor.id, deleteOptions)
            
            dataPoints = try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 50)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    
    

    func testUpdateValueOfDataPoint() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(100)
            queryOptions.limit = 100
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 1)
            XCTAssertEqual(dataPoints[0].getValueInString(), "String value")
            
            dataPoint = dataPoints[0]
            dataPoint.setValue("String value updated")
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            let updatedDataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(updatedDataPoints.count, 1)
            XCTAssertEqual(updatedDataPoints[0].getValueInString(), "String value updated")
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testCreateDataDeletionRequest(){
        var numberOfRequest = 0;
        let startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60 )
        let endTime = NSDate()
        do{
            try DatabaseHandler.createDataDeletionRequest("light", sourceName: "sony", startTime: startTime, endTime: endTime)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: startTime, endTime: endTime)
            numberOfRequest++
            let realm = try! Realm()
            let predicate = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            let results = realm.objects(DataDeletionRequest).filter(predicate)
            XCTAssertEqual(numberOfRequest, results.count)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testCreateDataDeletionRequestWithNilTime(){
        var numberOfRequest = 0;
        let startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60 )
        let endTime = NSDate()
        do{
            try DatabaseHandler.createDataDeletionRequest("light", sourceName: "sony", startTime: nil, endTime: endTime)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: startTime, endTime: nil)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: nil, endTime: nil)
            numberOfRequest++
            let realm = try! Realm()
            let predicate = NSPredicate(format: "userId = %@", KeychainWrapper.stringForKey(KEYCHAIN_USERID)!)
            let results = realm.objects(DataDeletionRequest).filter(predicate)
            XCTAssertEqual(numberOfRequest, results.count)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }

    }
    
    func testGetDataDeletionRequest() {
        var numberOfRequest = 0;
        let startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60 )
        let endTime = NSDate()
        do{
            try DatabaseHandler.createDataDeletionRequest("light", sourceName: "sony", startTime: nil, endTime: endTime)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: startTime, endTime: nil)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: nil, endTime: nil)
            numberOfRequest++
            let results = DatabaseHandler.getDataDeletionRequest()
            XCTAssertEqual(numberOfRequest, results.count)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }

    }
    
    func testDeleteDataDeletionRequest() {
        var numberOfRequest = 0;
        let startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60 )
        let endTime = NSDate()
        do{
            try DatabaseHandler.createDataDeletionRequest("light", sourceName: "sony", startTime: nil, endTime: endTime)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: startTime, endTime: nil)
            numberOfRequest++
            try DatabaseHandler.createDataDeletionRequest("gyroscope", sourceName: "htc", startTime: nil, endTime: nil)
            numberOfRequest++
            let results = DatabaseHandler.getDataDeletionRequest()
        
            for result in results {
                try DatabaseHandler.deleteDataDeletionRequest(result.uuid)
                numberOfRequest--
                let newResult = DatabaseHandler.getDataDeletionRequest()
                XCTAssertEqual(numberOfRequest, newResult.count)
            }
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testUpdateSyncedStatusOfDataPoint() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endTime = NSDate().dateByAddingTimeInterval(100)
            queryOptions.limit = 100
            
            let dataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(dataPoints.count, 1)
            XCTAssertEqual(dataPoints[0].getValueInString(), "String value")
            
            dataPoint = dataPoints[0]
            dataPoint.existsInRemote = true
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            let updatedDataPoints = try! DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            XCTAssertEqual(updatedDataPoints.count, 1)
            XCTAssert(updatedDataPoints[0].existsInRemote)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }


    func testInsertSensorWithValidSetup() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: "user1", remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    

    
    func testUpdateSensor() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorMeta: Dictionary<String, AnyObject>? = ["sensor":"meta data updated"]
            sensor.meta = newSensorMeta
            try DatabaseHandler.updateSensor(sensor)
            
            let retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(JSONUtils.stringify(retrievedSensor.meta!), JSONUtils.stringify(newSensorMeta!))
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensors() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let retrievedSensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(retrievedSensors.count, 2)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSources() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            //add 2 sensors with source 1 and add 1 sensor with source 2
            var sensor = Sensor(name: "sensor1", source: "testSource1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", source: "testSource1", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            //add 1 sensor with another userId and source3
            sensor = Sensor(name: "sensor3", source: "testSource2",  sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            //call getSources
            let sources = DatabaseHandler.getSources()
            XCTAssertEqual(sources.count, 2)
            XCTAssertEqual(sources[0], "testSource1")
            XCTAssertEqual(sources[1], "testSource2")
            
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorWithSourceNameAndSensorName() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testCreateAndGetSensorProfile() {
        do{
            let sensorName = "accelerometer"
            let dataStructure = "{\"$schema\": \"http://json-schema.org/draft-04/schema#\", \"description\": \"The time physically active in seconds\", \"type\": \"integer\"}"
            try DatabaseHandler.createOrUpdateSensorProfile(sensorName, dataStructure: dataStructure)
            let profile = try DatabaseHandler.getSensorProfile(sensorName)
            XCTAssert(dataStructure == profile?.dataStructure)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testDeleteSensorProfile() {
        do{
            let sensorName = "accelerometer"
            let dataStructure = "{\"$schema\": \"http://json-schema.org/draft-04/schema#\", \"description\": \"The time physically active in seconds\", \"type\": \"integer\"}"
            try DatabaseHandler.createOrUpdateSensorProfile(sensorName, dataStructure: dataStructure)
            var profile: SensorProfile? = try DatabaseHandler.getSensorProfile(sensorName)
            XCTAssert(dataStructure == profile?.dataStructure)
            
            //== delete
            try DatabaseHandler.deleteSensorProfile(sensorName)
            // check nil is returned after deletion
            profile = try DatabaseHandler.getSensorProfile(sensorName)
            XCTAssert(profile == nil)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    // MARK: Invalid cases
    
    func testInsertDataPointWithInvalidSensorId() {
        do{
            let dataPoint = DataPoint(sensorId: 1, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetDataPointsWithInvalidLimit() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "StringValue", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "StringValue", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.endTime = NSDate()
            queryOptions.limit = -1
            
            try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }
    
    func testGetDataPointsWithStartTimeLaterThanEndTime() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var sensors = [Sensor]()
            sensors = DatabaseHandler.getSensors(sourceName)
            XCTAssertEqual(sensors.count, 1)
            
            var dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            dataPoint = DataPoint(sensorId: sensor.id, value: "String value", time: NSDate())
            try DatabaseHandler.insertOrUpdateDataPoint(dataPoint)
            
            var queryOptions = QueryOptions()
            queryOptions.startTime = NSDate()
            queryOptions.endTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
            queryOptions.limit = 100
            
            try DatabaseHandler.getDataPoints(sensor.id, queryOptions)
            
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }
    
    func testGetDataPointsWithInvalidSensorId() {
        
        var queryOptions = QueryOptions()
        queryOptions.startTime = NSDate().dateByAddingTimeInterval( -7 * 24 * 60 * 60)
        queryOptions.endTime = NSDate()
        
        do{
            let dataPoints = try DatabaseHandler.getDataPoints(1, queryOptions)
            XCTAssertEqual(dataPoints.count, 0)
        }catch{
            print(error)
        }
    }
    
    
    func testInsertSameSensorTwice() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            let sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            try DatabaseHandler.insertSensor(sensor)
            
        }catch{
            print((error))
            XCTAssertNotNil(error)
        }
    }
    
    func testInsertSensorWithInvalidUserId() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", source: "testSource", sensorConfig: sensorConfig, userId: "anotheruser", remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testUpdateInvalidUpdateOfSensorName() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", source: "testSource", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorName = "new SensorName"
            sensor.name = newSensorName
            try DatabaseHandler.updateSensor(sensor)
        }catch{
            print(error)
            XCTAssertNotNil(error)
        }
    }
    
    func testUpdateSensorWithInvalidUsername() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sensor = Sensor(name: "sensor1", source: "testSource", sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let newSensorName = "sensor1Updated"
            sensor.name = newSensorName
            sensor.userId = "AnotherUser"
            try DatabaseHandler.updateSensor(sensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetSensorWithNonExistingSource() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try DatabaseHandler.getSensor("nonExistingSorce", sensor.name)
            XCTAssertNil(retrievedSensor)
        }catch{
            XCTAssertNotNil(error)
        }
    }
    
    func testGetSensorWithNonExistingSensorName() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!,  remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            var retrievedSensor = try! DatabaseHandler.getSensor(sourceName, sensor.name)
            XCTAssertEqual(retrievedSensor.name, sensor.name)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            retrievedSensor = try DatabaseHandler.getSensor(sourceName, "NonExsistingSensorName")
        }catch{
            XCTAssertNotNil(error)
        }
    }
    

    
    func testGetSensorsWithInvalidSorceName() {
        let sensorConfig = SensorConfig(meta: nil, uploadEnabled: true, downloadEnabled: true, persist: true)
        do{
            let sourceName = "testSource"
            var sensor = Sensor(name: "sensor1", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            sensor = Sensor(name: "sensor2", source: sourceName, sensorConfig: sensorConfig, userId: KeychainWrapper.stringForKey(KEYCHAIN_USERID)!, remoteDataPointsDownloaded: false)
            try DatabaseHandler.insertSensor(sensor)
            
            let retrievedSensors = DatabaseHandler.getSensors("NonExistingSourceName")
            XCTAssertEqual(retrievedSensors.count, 0)
        }catch{
            XCTFail("Exception was captured. Abort the test.")
        }
    }
    
    func testGetSensorsWithValidSorceNameWithoutSensors() {
        let retrievedSensors = DatabaseHandler.getSensors("NonExistingSourceName")
        XCTAssertEqual(retrievedSensors.count, 0)
    }
    


}

