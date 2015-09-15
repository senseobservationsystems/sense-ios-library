//
//  CSSensorRequirements.m
//  SensePlatform
//
//  Created by Pim Nijdam on 4/15/13.
//
//

#import "CSSensorRequirements.h"
#import "CSSettings.h"
#import "CSSensePlatform.h"

NSString* const kCSREQUIREMENT_FIELD_OPTIONAL = @"optional";
NSString* const kCSREQUIREMENT_FIELD_SENSOR_NAME = @"sensor_name";
NSString* const kCSREQUIREMENT_FIELD_REASON = @"reason";
NSString* const kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL = @"sample_interval";
NSString* const kCSREQUIREMENT_FIELD_SAMPLE_ACCURACY = @"sample_accuracy";
NSString* const kCSREQUIREMENT_FIELD_AT_TIME = @"at_time";

@implementation CSSensorRequirements {
    /* Datastructure: requirementsPerConsumer is an dictionary indexed by consumer. The value is an array of requirements. A requirement is a dictionary.
    */
    NSMutableDictionary* requirementsPerConsumer;
    
    //lock to prevent problems when updating requirements from different threads
    NSObject* lock;
    //actionQueue used to set the setting after a requirement is updated. This is a sequential queue to ensure proper ordering
    dispatch_queue_t actionQueue;
}

#pragma mark Singleton functions

//Singleton instance
static CSSensorRequirements* sharedRequirementsInstance = nil;

+ (CSSensorRequirements*) sharedRequirements {
	if (sharedRequirementsInstance == nil) {
		sharedRequirementsInstance = [[[self class] alloc] init];
	}
	return sharedRequirementsInstance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) init {
    self = [super init];
    if (self) {
        lock = [[NSObject alloc] init];
        actionQueue = dispatch_queue_create("requirements update queue", 0);
        requirementsPerConsumer = [[NSMutableDictionary alloc] init];
        self.isEnabled = YES;
    }
    return self;
}

#pragma mark - Interface functions

- (NSArray*) uglyHackForBurstSensors:(NSArray*) requirements {
    NSMutableArray* newSet = [requirements mutableCopy];
    for (NSDictionary* requirement in requirements) {
        NSString* sensorName = requirement[kCSREQUIREMENT_FIELD_SENSOR_NAME];
        NSRange range = [sensorName rangeOfString:@" (burst-mode)"];
        if (range.location != NSNotFound) {
            NSMutableDictionary* new = [requirement mutableCopy];
            NSString* nonBurstSensor = [sensorName substringWithRange:NSMakeRange(0, range.location)];
            new[kCSREQUIREMENT_FIELD_SENSOR_NAME] = nonBurstSensor;
            [newSet addObject:new];
        }
    
    }
    return newSet;
}

- (void) setRequirements:(NSArray*) requirements byConsumer:(NSString*) consumer {
    @synchronized(lock) {
    requirements = [self uglyHackForBurstSensors:requirements];
    
    NSDictionary* previous = [requirementsPerConsumer copy];
    [requirementsPerConsumer setValue:requirements forKey:consumer];
    
    if (self.isEnabled) {
        [self performActionForRequirementsUpdateFrom:previous to:[requirementsPerConsumer copy]];
    }
    }
}

- (void) clearRequirementsForConsumer:(NSString*) consumer {
    @synchronized(lock) {
     NSDictionary* previous = [requirementsPerConsumer copy];
    [requirementsPerConsumer removeObjectForKey:consumer];

    if (self.isEnabled) {
        [self performActionForRequirementsUpdateFrom:previous to:[requirementsPerConsumer copy]];
    }
    }
}

- (void) setIsEnabled:(BOOL)isEnabled {
    if (isEnabled) {
        [self performActionForRequirementsUpdateFrom:nil to:[requirementsPerConsumer copy]];
    } else {
        [self performActionForRequirementsUpdateFrom:[requirementsPerConsumer copy] to:nil];
    }
    _isEnabled = isEnabled;
}

+ (NSDictionary*) requirementForSensor:(NSString*) sensor {
    return @{kCSREQUIREMENT_FIELD_SENSOR_NAME:sensor};
}

+ (NSDictionary*) requirementForSensor:(NSString*) sensor withInterval:(NSTimeInterval)interval {
    return @{kCSREQUIREMENT_FIELD_SENSOR_NAME:sensor, kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL:[NSNumber numberWithDouble:interval]};
}

#pragma mark - Private functions

- (void) performActionForRequirementsUpdateFrom:(NSDictionary*) previousRequirements to:(NSDictionary*) newRequirements {
    //dispatch this to prevent a possible deadlock. If action code tries to get the requirement lock.
    //Just to be sure, could happen if requirements are set as a consequent of another requirement
    dispatch_async(actionQueue, ^() {
        NSDictionary* perSensorOld = [self perSensorRequirementsFrom:previousRequirements];
        NSDictionary* perSensorNew = [self perSensorRequirementsFrom:newRequirements];
        
        //for all sensors in old but not in new, disable them
        for (NSString* sensor in perSensorOld) {
            NSArray* list = [perSensorNew valueForKey:sensor];
            if (list == nil) {
                //disable the sensor
                [[CSSettings sharedSettings] setSensor:sensor enabled: NO];
            }
        }
        
        NSNumber* motionSampleInterval;
        NSArray* motionSensors = @[kCSSENSOR_ACCELERATION, kCSSENSOR_ACCELEROMETER, kCSSENSOR_MOTION_ENERGY, kCSSENSOR_MOTION_FEATURES, kCSSENSOR_ORIENTATION, kCSSENSOR_ROTATION, kCSSENSOR_ACCELERATION_BURST, kCSSENSOR_ACCELEROMETER_BURST, kCSSENSOR_ROTATION_BURST, kCSSENSOR_ORIENTATION_BURST];
        
        //for all sensors in new, update settings
        for (NSString* sensor in perSensorNew) {
            NSDictionary* oldRequirement = [self mergeRequirements:[perSensorOld valueForKey:sensor] forSensor:sensor];
            NSDictionary* newRequirement = [self mergeRequirements:[perSensorNew valueForKey:sensor] forSensor:sensor];
            [self updateSettingFromRequirement:oldRequirement to:newRequirement];
            
            //merge all motion intervals into a single value
            if ([motionSensors containsObject:sensor]) {
                NSNumber* interval = [newRequirement valueForKey:kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL];
                if (interval != nil) {
                    if (motionSampleInterval == nil)
                        motionSampleInterval = interval;
                    else if ([interval doubleValue] < [motionSampleInterval doubleValue])
                        motionSampleInterval = interval;
                }
            }
        }
        
        if (motionSampleInterval != nil) {
            double currentValue = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval] doubleValue];
            if (currentValue != [motionSampleInterval doubleValue])
                [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:[motionSampleInterval stringValue]];
        }
    });
}


- (NSDictionary*) perSensorRequirementsFrom:(NSDictionary*)perConsumerRequirements {
    NSMutableDictionary* perSensor = [[NSMutableDictionary alloc] init];
    for (NSString* consumer in perConsumerRequirements) {
        NSArray* requirements = [perConsumerRequirements valueForKey:consumer];
        for (NSDictionary* requirement in requirements) {
            NSString* sensor = [requirement valueForKey:kCSREQUIREMENT_FIELD_SENSOR_NAME];
            NSMutableArray* list = [perSensor valueForKey:sensor];
            if (list == nil) {
                list = [[NSMutableArray alloc] init];
                [perSensor setValue:list forKey:sensor];
            }
            [list addObject:requirement];
        }
    }
    
    return perSensor;
}

/** Merge requirements.
 *  Default strategy is to take the minimum for all fields
 */
- (NSDictionary*) mergeRequirements:(NSArray*) requirements forSensor:(NSString*) sensor {
    size_t noMerged = 0;

    //assume all requirements are for the same sensor
    NSMutableDictionary* merged = [[NSMutableDictionary alloc] init];
    [merged setValue:sensor forKey:kCSREQUIREMENT_FIELD_SENSOR_NAME];
    for (NSDictionary* requirement in requirements) {
        //skip requirements not for this sensor
        if (NO == [sensor isEqualToString:[requirement valueForKey:kCSREQUIREMENT_FIELD_SENSOR_NAME] ]) {
            continue;
        }
        noMerged += 1;
            
        for (NSString* field in requirement) {
            id value = [requirement valueForKey:field];
            id original = [merged valueForKey:field];
            if (original == nil) {
                [merged setValue:value forKey:field];
                continue;
            }
            if ([value isKindOfClass:[NSNumber class]] && [original isKindOfClass:[NSNumber class]] && [value doubleValue] < [original doubleValue]) {
                [merged setValue:value forKey:field];
            }
        }
    }
    
    if (noMerged > 0) {
        return merged;
    } else {
        return nil;
    }
}

- (void) updateSettingFromRequirement:(NSDictionary*) from to:(NSDictionary*) to {
    NSString* sensor = [to valueForKey:kCSREQUIREMENT_FIELD_SENSOR_NAME];
    
    if ([to isEqualToDictionary:from]) {
        return;
    }

    if (to == nil && from != nil) {
        //disable sensor
        NSString* sensor = [to valueForKey:kCSREQUIREMENT_FIELD_SENSOR_NAME];
        [[CSSettings sharedSettings] setSensor:sensor enabled:NO];
        return;
    }
    
    if ([sensor isEqualToString:kCSSENSOR_LOCATION]) {
        NSNumber* accuracy = [to valueForKey:kCSREQUIREMENT_FIELD_SAMPLE_ACCURACY];
        if (accuracy != nil) {
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:[accuracy stringValue]];
        }
    }
    
    if ([sensor isEqualToString:kCSSENSOR_NOISE]) {
        NSNumber* interval = [to valueForKey:kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL];
        if (interval != nil) {
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:[interval stringValue]];
        }
    }
    
    //enable sensor, if neccessary
    if (from == nil && to != nil) {
        //enable sensor
        [[CSSettings sharedSettings] setSensor:sensor enabled:YES];
    }
}

@end
