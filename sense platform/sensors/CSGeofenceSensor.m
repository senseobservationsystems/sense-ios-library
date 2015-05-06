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

NSMutableArray* activeRegions; //stores currently active regions (as CLRegions, e.g. "[5.210230, 12.423857, AGORAPHOBIA]")




- (NSString*) name {
    return [kCSSENSOR_GEOFENCE stringByAppendingString:sensorNameSuffix];
}
- (NSString*) deviceType {return [self name];}

+ (BOOL) isAvailable {
    return [[UIDevice currentDevice].systemVersion intValue] >= 8;
}

- (NSDictionary*) sensorDescription {
    //create description for data format. programmer: make SURE it matches the format used to send data
    //TODO later
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
    if (isEnabled == NO || [self isActive:identifier] == NO) {
        return;
    }
    
    sensorNameSuffix = [@"_" stringByAppendingString:identifier];
    int outOfRange = enter ? 0 : 1;
    
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:outOfRange], outOfRangeKey,
                                    nil];
    
    double timestamp = [[NSDate date] timeIntervalSince1970]; //TODO do we want it to happen NOW? or get from locationmanager?
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        newItem, @"value",
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

- (void) dealloc {
    self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
