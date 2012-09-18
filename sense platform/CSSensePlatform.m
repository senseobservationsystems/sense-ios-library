#import "CSSensePlatform.h"
#import "CSSensorStore.h"
#import "CSSettings.h"
#import "CSDynamicSensor.h"
//#import "BloodPressureSensor.h"

NSString * const kCSDATA_TYPE_JSON = @"json";
NSString * const kCSDATA_TYPE_INTEGER = @"integer";
NSString * const kCSDATA_TYPE_FLOAT = @"float";
NSString * const kCSDATA_TYPE_STRING = @"string";
NSString* const kCSNewSensorDataNotification = @"CSNewSensorDataNotification";

static CSSensorStore* sensorStore;


@implementation CSSensePlatform {

}

+ (void) initialize {
    sensorStore = [CSSensorStore sharedSensorStore];
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

+ (void) flushDataAndBlock {
    [sensorStore forceDataFlush];
}

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password {
    [[CSSettings sharedSettings] setLogin:user withPassword:password];
    return [sensorStore.sender login];
}

+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password {

    NSString* error;
    BOOL succes = [sensorStore.sender registerUser:user withPassword:password error:&error];
    if (succes)
            [[CSSettings sharedSettings] setLogin:user withPassword:password];
    return succes;
        
}

+ (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints {
    return [[CSSensorStore sharedSensorStore] getDataForSensor:name onlyFromDevice:onlyFromDevice nrLastPoints:nrLastPoints];
}

+(void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label {
    [sensorStore giveFeedbackOnState:state from:from to:to label:label];
}

+ (void) applyIVitalitySettings {
    CSSettings* settings = [CSSettings sharedSettings];
    [settings setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"60"];
    [settings setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"60"];
    [settings setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval value:@"900"];
    [settings setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"10000"];

    [settings setSensor:kCSSENSOR_LOCATION enabled:YES];
    [settings setSensor:kCSSENSOR_BATTERY enabled:YES];
    [settings setSensor:kCSSENSOR_NOISE enabled:YES];
    [settings setSensor:kCSSENSOR_ACCELEROMETER enabled:YES];
    [settings setSensor:kCSSENSOR_ACCELERATION enabled:YES];
    [settings setSensor:kCSSENSOR_ORIENTATION enabled:YES];
    [settings setSensor:kCSSENSOR_ROTATION enabled:YES];
    [settings setSensor:kCSSENSOR_MOTION_ENERGY enabled:YES];
    
    [settings setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingSenseEnabled value:kCSSettingYES];
}

+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp {
    
    NSMutableDictionary* fields;

    if ([dataType isEqualToString:kCSDATA_TYPE_JSON]) {
        fields = [[NSMutableDictionary alloc] init];
        //extract data structure from value
        @try {
            NSDictionary* values = [value JSONValue];
            for (NSString* key in values) {
                NSString* type = [CSSensePlatform dataTypeOf:[values objectForKey:key]];
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
    CSDynamicSensor* sensor = [[CSDynamicSensor alloc] initWithName:sensorName displayName:displayName deviceType:deviceType dataType:dataType fields:fields];
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
    
    //hmm, value might be anything, let's write it to a string
    NSString* stringValue = [NSString stringWithFormat:@"%@", value];
    NSNumber* number = [f numberFromString:stringValue];
    if (number) {
        if ([stringValue rangeOfString:@"."].location == NSNotFound)
            return kCSDATA_TYPE_INTEGER;
        else {
            return kCSDATA_TYPE_FLOAT;
        }
    }
    return kCSDATA_TYPE_STRING;
}
@end