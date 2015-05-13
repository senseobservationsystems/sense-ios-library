//
//  CSGeofenceSensor.m
//  SensePlatform
//
//  Created by Yfke Dulek on 06/05/15.
//
//

#import "CSGeofenceSensor.h"
#import "CSDataStore.h"
#import "Formatting.h"


@implementation CSGeofenceSensor

static NSString* outOfRangeKey = @"out of range";

NSString* sensorNameSuffix; // e.g. "_AGORAPHOBIA"

NSMutableArray* activeRegions; //stores currently active regions (as CLRegions wit lat/lon, radius and name, e.g. [5.210230, 12.423857, 100.0, AGORAPHOBIA])




- (NSString*) name {
    return [kCSSENSOR_GEOFENCE stringByAppendingString:sensorNameSuffix];
}
- (NSString*) deviceType {return [self name];}

+ (BOOL) isAvailable {
    return [[UIDevice currentDevice].systemVersion intValue] >= 7; //TODO check that this is correct (could also be lower)
}

- (NSDictionary*) sensorDescription {
    //create description for data format. programmer: make SURE it matches the format used to send data
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"int", outOfRangeKey,
                            nil];
    //make string, as per spec
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self name], @"name",
            [self deviceType], @"device_type",
            @"", @"pager_type",
            @"json", @"data_type",
            json, @"data_structure",
            nil];
}

- (id) init {
    self = [super init];
    
    if (self) {
        sensorNameSuffix = @"";
        activeRegions = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (BOOL) isActive:(NSString *)regionId {
    return [activeRegions indexOfObject:regionId] != NSNotFound;
}

- (NSMutableArray*) activeRegions {return activeRegions;}

- (void) storeRegionEvent: (CLRegion *) region withEnterRegion: (BOOL) enter {
    NSString* identifier = region.identifier;
    //If the entire geofence sensor is disabled, OR if the current region/fence is not actively being listened for,
    //do nothing
    if (isEnabled == NO || [self isActive:region.identifier] == NO) {
        return;
    }
    
    sensorNameSuffix = [@"_" stringByAppendingString:region.identifier];
    int outOfRange = enter ? 0 : 1;
    
    NSMutableDictionary* newEvent = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:outOfRange], outOfRangeKey,
                                    nil];
    
    double timestamp = [[NSDate date] timeIntervalSince1970]; //TODO do we want timestamp to be NOW? or get time from locationmanager somehow? (difference would be only a couple of milliseconds)
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        newEvent, @"value",
                                        CSroundedNumber(timestamp, 3), @"date",
                                        nil];
    [dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
    NSLog(@"%@ %@ sensor (id=%@).", enable ? @"Enabling":@"Disabling", [self class], self.sensorId);
    isEnabled = enable;
}

- (void) addRegion:(CLRegion*) region {
    [activeRegions addObject:region];
}

- (void) removeRegion:(CLRegion*) region {
    [activeRegions removeObject:region];
}

- (CLRegion*) getRegionWithIdentifier:(NSString*) identifier {
    NSPredicate* equalToId = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
    NSArray* results = [activeRegions filteredArrayUsingPredicate:equalToId];
    if([results count] == 0)
        //No regions that match the given identifier
        return Nil;
    else
        return [results firstObject];
}

//TODO I don't know how to implement this method. below is a copy-paste from the visits sensor, but
//it needs to be checked that this is correct for the geofence sensor as well
- (void) dealloc {
    self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
