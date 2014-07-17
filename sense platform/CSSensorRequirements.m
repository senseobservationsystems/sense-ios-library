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
}

#pragma mark Singleton functions

//Singleton instance
static CSSensorRequirements* sharedRequirementsInstance = nil;

+ (CSSensorRequirements*) sharedRequirements {
	if (sharedRequirementsInstance == nil) {
		sharedRequirementsInstance = [[super allocWithZone:NULL] init];
	}
	return sharedRequirementsInstance;
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedRequirements];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) init {
    self = [super init];
    if (self) {
        requirementsPerConsumer = [[NSMutableDictionary alloc] init];
        self.isEnabled = YES;
    }
    return self;
}

#pragma mark - Interface functions

- (void) setRequirements:(NSArray*) requirements byConsumer:(NSString*) consumer {
    NSDictionary* previous = [requirementsPerConsumer copy];
    [requirementsPerConsumer setValue:requirements forKey:consumer];
    
    if (self.isEnabled) {
        [self performActionForRequirementsUpdateFrom:previous to:requirementsPerConsumer];
    }
}

- (void) clearRequirementsForConsumer:(NSString*) consumer {
     NSDictionary* previous = [requirementsPerConsumer copy];
    [requirementsPerConsumer removeObjectForKey:consumer];

    if (self.isEnabled) {
        [self performActionForRequirementsUpdateFrom:previous to:requirementsPerConsumer];
    }

}

- (void) setIsEnabled:(BOOL)isEnabled {
    if (isEnabled) {
        //TODO: disable all sensors
        [self performActionForRequirementsUpdateFrom:nil to:requirementsPerConsumer];
    } else {
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
    
    //for all sensors in new, update settings
    for (NSString* sensor in perSensorNew) {
        NSDictionary* oldRequirement = [self mergeRequirements:[perSensorOld valueForKey:sensor] forSensor:sensor];
        NSDictionary* newRequirement = [self mergeRequirements:[perSensorNew valueForKey:sensor] forSensor:sensor];
        [self updateSettingFromRequirement:oldRequirement to:newRequirement];
    }
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
    
    //TODO: improve! for now just some ad-hoc code to make it work
    //TODO: merge fields for motion sensors
    
    NSArray* motionSensors = @[kCSSENSOR_ACCELERATION, kCSSENSOR_ACCELEROMETER, kCSSENSOR_MOTION_ENERGY, kCSSENSOR_MOTION_FEATURES, kCSSENSOR_ORIENTATION, kCSSENSOR_ROTATION, kCSSENSOR_ACCELERATION_BURST, kCSSENSOR_ACCELEROMETER_BURST, kCSSENSOR_ROTATION_BURST, kCSSENSOR_ORIENTATION_BURST];

    if ([motionSensors containsObject:sensor]) {
        //set interval setting
        NSNumber* interval = [to valueForKey:kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL];
        if (interval != nil) {
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:[interval stringValue]];
        }
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
