#import "SensePlatform.h"
#import "SensorStore.h"
#import "Settings.h"
#import "DynamicSensor.h"
//#import "BloodPressureSensor.h"

NSString * const kSENSEPLATFORM_DATA_TYPE_JSON = @"json";
NSString * const kSENSEPLATFORM_DATA_TYPE_INTEGER = @"integer";
NSString * const kSENSEPLATFORM_DATA_TYPE_FLOAT = @"float";
NSString * const kSENSEPLATFORM_DATA_TYPE_STRING = @"string";

NSString* const kNewSensorDataNotification = @"NewSensorDataNotification";


static SensorStore* sensorStore; 



@implementation SensePlatform {

}

+ (void) initialize {
    sensorStore = [SensorStore sharedSensorStore];
}

+ (NSArray*) availableSensors {
    return sensorStore.sensors;
}

+ (void) willTerminate {
    [sensorStore forceDataFlush];
}

+ (void) flushData {
    [sensorStore forceDataFlush];
}

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password {
    [[Settings sharedSettings] setLogin:user withPassword:password];
    return [sensorStore.sender login];
}

+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password {

    NSString* error;
    BOOL succes = [sensorStore.sender registerUser:user withPassword:password error:&error];
    if (succes)
            [[Settings sharedSettings] setLogin:user withPassword:password];
    return succes;
        
}

+ (NSDictionary*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints {
    return [[SensorStore sharedSensorStore] getDataForSensor:name onlyFromDevice:onlyFromDevice nrLastPoints:nrLastPoints];
}

+ (void) applyIVitalitySettings {
    Settings* settings = [Settings sharedSettings];
    [settings setSettingType:kSettingTypeSpatial setting:kSpatialSettingInterval value:@"60"];
    [settings setSettingType:kSettingTypeAmbience setting:kAmbienceSettingInterval value:@"60"];
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingUploadInterval value:@"900"];

    [settings setSensor:kSENSOR_LOCATION enabled:NO];
    [settings setSensor:kSENSOR_BATTERY enabled:YES];
    [settings setSensor:kSENSOR_NOISE enabled:YES];
    [settings setSensor:kSENSOR_ACCELEROMETER enabled:YES];
    [settings setSensor:kSENSOR_ACCELERATION enabled:YES];
    [settings setSensor:kSENSOR_ORIENTATION enabled:YES];
    [settings setSensor:kSENSOR_ROTATION enabled:YES];
    [settings setSensor:kSENSOR_MOTION_ENERGY enabled:YES];
    
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingSenseEnabled value:kSettingYES];
}

+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp {
    
    NSMutableDictionary* fields;

    if ([dataType isEqualToString:kSENSEPLATFORM_DATA_TYPE_JSON]) {
        fields = [[NSMutableDictionary alloc] init];
        //extract data structure from value
        @try {
            NSDictionary* values = [value JSONValue];
            for (NSString* key in values) {
                NSString* type = [SensePlatform dataTypeOf:[values objectForKey:key]];
                if (type == nil)
                    type = @"";
                [fields setObject:type forKey:key];
            }
            
        }
        @catch (NSException *exception) {
            NSLog(@"SensePlatform addDataPointForSensor: error extracting datatype from sensor value");
        }
    }
    
    //create sensor
    DynamicSensor* sensor = [[DynamicSensor alloc] initWithName:sensorName displayName:displayName deviceType:deviceType dataType:dataType fields:fields];
    //add sensor to the sensor store
    [sensorStore addSensor:sensor];
    //commit value
    [sensor commitValue:value withTimestamp:[NSString stringWithFormat:@"%.3f",[timestamp timeIntervalSince1970]]];
}

+ (void) synchronizeWithBloodPressureMonitor:(bpmCallBack) callback {
    /*
    BloodPressureSensor* bpm;
    for (Sensor* sensor in sensorStore.sensors) {
        if ([sensor isKindOfClass:BloodPressureSensor.class]) {
            bpm = (BloodPressureSensor*)sensor;
            break;
        }
            
    }
    if (bpm != nil)
        [bpm syncMeasurements:callback];
    else {
        callback(BPM_OTHER_ERROR, 0, 0, nil);
    }
     */
}


+ (NSString*) dataTypeOf:(NSString*) value {
    NSNumberFormatter* f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber* number = [f numberFromString:value];
    if (number) {
        if ([value rangeOfString:@"."].location == NSNotFound)
            return kSENSEPLATFORM_DATA_TYPE_INTEGER;
        else {
            return kSENSEPLATFORM_DATA_TYPE_FLOAT;
        }
    }
    return kSENSEPLATFORM_DATA_TYPE_STRING;
}
@end