/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import "CSSensePlatform.h"
#import "CSSensorStore.h"
#import "CSSettings.h"
#import "CSDynamicSensor.h"
#import "CSVersion.h"
//#import "BloodPressureSensor.h"

NSString * const kCSDATA_TYPE_JSON = @"json";
NSString * const kCSDATA_TYPE_INTEGER = @"integer";
NSString * const kCSDATA_TYPE_FLOAT = @"float";
NSString * const kCSDATA_TYPE_STRING = @"string";
NSString * const kCSDATA_TYPE_BOOL = @"bool";
NSString* const kCSNewSensorDataNotification = @"CSNewSensorDataNotification";
NSString* const kCSNewMotionDataNotification = @"CSNewMotionDataNotification";

static CSSensorStore* sensorStore;

@implementation CSSensePlatform {

}

+ (void) initialize {
    sensorStore = [CSSensorStore sharedSensorStore];
    
    //store version information
    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString* appIdentifier = [NSBundle mainBundle].bundleIdentifier;
    NSString* buildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString * appVersionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    NSString* locale = [[NSLocale currentLocale] localeIdentifier];
    
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
#ifdef SENSE_PLATFORM_VERSION
                          [NSString stringWithFormat:@"%s", SENSE_PLATFORM_VERSION], @"sense_platform_version",
#else
#error SENSE_PLATFORM_VERSION undefined
#endif
                          appName, @"app_name",
                          appVersionString, @"app_version",
                          buildVersion, @"app_build",
                          locale, @"locale",
                          [UIDevice currentDevice].systemName, @"os",
                          [UIDevice currentDevice].systemVersion, @"os_version",
                          nil];
    //add data point for app version
    [CSSensePlatform addDataPointForSensor:@"app_version" displayName:@"App Version" description:appIdentifier dataType:kCSDATA_TYPE_JSON jsonValue:data timestamp:[NSDate date]];
}

+ (NSArray*) availableSensors {
    return [CSSensorStore sharedSensorStore].sensors;
}

+ (void) willTerminate {
    [[CSSensorStore sharedSensorStore] forceDataFlush];
}

+ (void) flushData {
    [[CSSensorStore sharedSensorStore] forceDataFlush];
}

+ (void) flushDataAndBlock {
    [[CSSensorStore sharedSensorStore] forceDataFlushAndBlock];
}

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password {
    [[CSSettings sharedSettings] setLogin:user withPassword:password];
    BOOL succeed = [[CSSensorStore sharedSensorStore].sender login];
    if (succeed) {
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense value:kCSSettingYES];
    }
    return succeed;
}

+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash {
    [[CSSettings sharedSettings] setLogin:user withPasswordHash:passwordHash];
    BOOL succeed = [sensorStore.sender login];
    if (succeed) {
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense value:kCSSettingYES];
    }
    
    return succeed;
}

+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password  withEmail:(NSString*) email {

    NSString* error;
    BOOL succes = [[CSSensorStore sharedSensorStore].sender registerUser:user withPassword:password withEmail:email error:&error];
    if (succes)
        [CSSensePlatform loginWithUser:user andPassword:password];
    return succes;
}

+ (void) logout {
    [[CSSettings sharedSettings] setLogin:@"" withPassword:@""];
    [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense value:kCSSettingNO];
}

+ (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints {
    return [[CSSensorStore sharedSensorStore] getDataForSensor:name onlyFromDevice:onlyFromDevice nrLastPoints:nrLastPoints];
}

+ (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label {
    [[CSSensorStore sharedSensorStore] giveFeedbackOnState:state from:from to:to label:label];
}

+ (NSString*) getSessionCookie {
    NSString* cookie = [CSSensorStore sharedSensorStore].sender.sessionCookie;
    if (cookie == nil) {
        NSString* user = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
        NSString* hash = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword];
        [CSSensePlatform loginWithUser:user andPasswordHash:hash];
        cookie = [CSSensorStore sharedSensorStore].sender.sessionCookie;
    }
    return cookie;
}

+ (void) applyIVitalitySettings {
    CSSettings* settings = [CSSettings sharedSettings];
    [settings setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"60"];
    [settings setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingFrequency value:@"20"];
    [settings setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingNrSamples value:@"20"];
    
    [settings setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"240"];
    [settings setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"10000"];
    [settings setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingMinimumDistance value:@"10000"];
    
    [settings setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval value:@"900"];

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

+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString*)description dataType:(NSString*)dataType jsonValue:(id)value timestamp:(NSDate*)timestamp {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [CSSensePlatform addDataPointForSensor:sensorName displayName:displayName description:description device:[CSSensorStore device] dataType:dataType stringValue:jsonString timestamp:timestamp];
}

+ (void) addDataPointForSensor:(NSString *)sensorName displayName:(NSString *)displayName description:(NSString *)description dataType:(NSString *)dataType stringValue:(NSString *)value timestamp:(NSDate *)timestamp {
    [CSSensePlatform addDataPointForSensor:sensorName displayName:displayName description:description device:[CSSensorStore device] dataType:dataType stringValue:value timestamp:timestamp];
}

+ (void) addDataPointForSensor:(NSString *)sensorName displayName:(NSString *)displayName description:(NSString *)description deviceType:(NSString *)deviceType deviceUUID:(NSString *)deviceUUID dataType:(NSString *)dataType jsonValue:(id)value timestamp:(NSDate *)timestamp {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:value options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							deviceUUID, @"uuid",
							deviceType, @"type",
							nil];
    if (deviceType == nil || deviceUUID == nil)
        device = nil;
    
    [CSSensePlatform addDataPointForSensor:sensorName displayName:displayName description:description device:device dataType:dataType stringValue:jsonString timestamp:timestamp];
}

+ (void) addDataPointForSensor:(NSString *)sensorName displayName:(NSString *)displayName description:(NSString *)description deviceType:(NSString *)deviceType deviceUUID:(NSString *)deviceUUID dataType:(NSString *)dataType stringValue:(NSString *)value timestamp:(NSDate *)timestamp {
    
    NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							deviceUUID, @"uuid",
							deviceType, @"type",
							nil];
    if (deviceType == nil || deviceUUID == nil)
        device = nil;
    
    [CSSensePlatform addDataPointForSensor:sensorName displayName:displayName description:description device:device dataType:dataType stringValue:value timestamp:timestamp];
}


+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString *)description device:(NSDictionary*)device dataType:(NSString*)dataType stringValue:(NSString*)value timestamp:(NSDate*)timestamp {
    
    NSMutableDictionary* fields;

    if ([dataType isEqualToString:kCSDATA_TYPE_JSON]) {
        fields = [[NSMutableDictionary alloc] init];
        //extract data structure from value
        @try {
            NSError* error = nil;
            NSData* jsonData = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary* values = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
            if (error)
                @throw [NSException exceptionWithName:@"Invalid JSON" reason:@"Value is not JSON" userInfo:nil];
            
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
    if (displayName == nil)
        displayName = sensorName;
    if (description == nil)
        description = sensorName;
    
    //create sensor
    CSDynamicSensor* sensor = [[CSDynamicSensor alloc] initWithName:sensorName displayName:displayName deviceType:description dataType:dataType fields:fields device:device];

    //add sensor to the sensor store
    [[CSSensorStore sharedSensorStore] addSensor:sensor];
    //commit value
    NSError* error;
    id jsonValue;
    if (value != nil)
        jsonValue = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    if (error != nil)
        jsonValue = value;
    [sensor commitValue:jsonValue withTimestamp:[timestamp timeIntervalSince1970]];
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