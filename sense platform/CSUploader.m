//
//  CSUploader.m
//  SensePlatform
//
//  Created by Pim Nijdam on 14/04/14.
//
//

#import "CSUploader.h"
#import "CSDataPoint.h"
#import "CSSensorStore.h"

static const size_t ROW_LIMIT = 100;

@implementation CSUploader {
    CSStorage* storage;
    CSSender* sender;
    long long lastUploadedRowId;
    NSDictionary* sensorIdCache;
}

- (id) initWithStorage:(CSStorage*) theStorage andSender:(CSSender*) theSender {
    self = [super init];
    if (self) {
        self->storage = theStorage;
        self->sender = theSender;
        //TODO: get this
        lastUploadedRowId = 0;
    }
    return self;
}

#pragma mark - Uploading

- (BOOL) upload {
    //get enough data from storage for a single upload
    //TODO: check size?
    NSArray* data = [storage getSensorDataPointsFromId:lastUploadedRowId limit:ROW_LIMIT];
    //extract sensors
    NSSet* sensors = getSensorSet(data);
    //resolve sensorids
    NSDictionary* sensorRemoteIds = [self resolveSensorIds:[sensors allObjects]];
    if (sensorRemoteIds == nil || sensorRemoteIds.count != sensors.count) {
        //TODO: handle error
        NSLog(@"Error couldn't resolve all sensorIds");
        return NO;
    }
    
    //create datastructure with data per sensorid
    NSArray* perSensorData = formattedData(data, sensorRemoteIds);
    
    //upload data
    BOOL succeed = [sender uploadDataForMultipleSensors:perSensorData];
    if (succeed) {
        CSDataPoint* last = [data lastObject];
        self->lastUploadedRowId = last.dataPointID;
        return YES;
    }
    return NO;

}

#pragma mark - Sensors

/* Return a dictionary with all resolved ids */
- (NSDictionary*) resolveSensorIds:(NSArray*) sensors {
    NSDictionary* resolved;
    
    //resolve locally from cache
    resolved = [self resolveFromCacheSensorIds:sensors];

    if (resolved.count == sensors.count) {
        //all sensors resolved, return
        return resolved;
    }
    
    //refresh cache and try to resolve again
    NSDictionary* refreshed = [self getRemoteSensors];
    if (refreshed == nil) {
        //TODO: handle error
        return nil;
    }
    
    self->sensorIdCache = refreshed;
    resolved = [self resolveFromCacheSensorIds:sensors];
    if (resolved.count == sensors.count) {
        return resolved;
    }
    
    //We got a couple of sensors that can't be found on the server. Create them
    size_t nrUnresolved = sensors.count - resolved.count;
    NSMutableArray* unresolved = [[NSMutableArray alloc] initWithCapacity:nrUnresolved];
    
    //create array of unresolved sensors
    for (NSString* sensorId in sensors) {
        if ([resolved valueForKey:sensorId] == nil) {
            [unresolved addObject:sensorId];
        }
    }
    
    //create each sensor
	for (NSString* sensorId in unresolved) {
        NSLog(@"Creating %@ sensor...", sensorId);
        NSDictionary* description = getSensorDescription(sensorId);
		NSDictionary* remoteDescription = [sender createSensorWithDescription:description];
        NSString* remoteId = [remoteDescription valueForKey:@"id"];
        if (remoteId == nil) {
            //TODO: handle error
            continue;
        }
        //link sensor to device
        NSDictionary* device = getSensorDevice(sensorId);
        if (device != nil) {
            [sender connectSensor:remoteId ToDevice:device];
            //TODO: handle error
        }
        [resolved setValue:remoteId forKey:sensorId];
    }
    
    //Note: the cache is not out-of-date and will be updated next time we try to resolve one of the created sensors
    
    return resolved;
}

- (NSDictionary*) resolveFromCacheSensorIds:(NSArray*) sensors {
    NSMutableDictionary* resolved = [[NSMutableDictionary alloc] initWithCapacity:sensors.count];
    for (NSString* sensorIdLocal in sensors) {
        NSString* remoteId = [sensorIdCache objectForKey:sensorIdLocal];
        if (remoteId != nil) {
            [resolved setObject:remoteId forKey:sensorIdLocal];
        }
    }
    return resolved;
}

- (NSDictionary*) getRemoteSensors {
    //get list of sensors from the server
    NSDictionary* response;
    NSArray* remoteSensors;
    response = [sender listSensors];
    remoteSensors = [response valueForKey:@"sensors"];
    
    NSMutableDictionary* mappedSensors = [[NSMutableDictionary alloc] initWithCapacity:remoteSensors.count];
    //create mappings
    for (id remoteSensor in remoteSensors) {
        //determine whether the sensor matches
        if ([remoteSensor isKindOfClass:[NSDictionary class]]) {
            NSString* name = [remoteSensor valueForKey:@"name"];
            NSString* description = [remoteSensor valueForKey:@"device_type"];
            NSDictionary* device = [remoteSensor valueForKey:@"device"];
            NSString* localId = [CSSensor sensorIdFromName:name andDeviceType:description andDevice:device];
            NSString* remoteId = [remoteSensor valueForKey:@"id"];
            [mappedSensors setValue:remoteId forKey:localId];
        }
    }
    return mappedSensors;
}


#pragma mark - Helper functions

NSSet* getSensorSet(NSArray* data) {
    NSMutableSet* sensorSet = [[NSMutableSet alloc] init];
    for (CSDataPoint* dp in data) {
        NSString* sensorId = [CSSensor sensorIdFromName:dp.sensor andDeviceType:dp.sensorDescription andDevice:dp.device];
        [sensorSet addObject:sensorId];
    }
    return sensorSet;
}

NSDictionary* getSensorDescription(NSString* sensorId) {
    //TODO: ensure descriptions end up in the table
    //TODO: get description from table
    NSString* name = [CSSensor sensorNameFromSensorId:sensorId];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			name, @"name",
			name, @"device_type",
			@"", @"pager_type",
			kCSDATA_TYPE_STRING, @"data_type",
			nil];
}

NSDictionary* getSensorDevice(NSString* sensorId) {
    //TODO: get device from the table
    return nil;
    return [CSSensorStore device];
}

NSArray* formattedData(NSArray* data, NSDictionary* sensorMapping) {
    /* data should be formatted like this:
     [{"sensor_id":"<id>", "data":[{<date values>}]}]
     */
    NSMutableDictionary* perSensor = [[NSMutableDictionary alloc] initWithCapacity:sensorMapping.count];
    
    for (CSDataPoint* dp in data) {
        NSString* sensorId = [CSSensor sensorIdFromName:dp.sensor andDeviceType:dp.sensorDescription andDevice:dp.device];
        NSString* remoteId = [sensorMapping valueForKey:sensorId];
        NSDictionary* sensorEntry = [perSensor valueForKey:remoteId];
        NSMutableArray* sensorData = [sensorEntry valueForKey:@"data"];
        if (sensorData == nil) {
            sensorData = [[NSMutableArray alloc] init];
            NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:sensorData, @"data", remoteId, @"sensor_id", nil];
            [perSensor setValue:d forKey:remoteId];
        }
        [sensorData addObject:dp.timeValueDict];
    }
    
    //per sensor actually needs to be an array, convert here
    return [perSensor allValues];
}

@end
