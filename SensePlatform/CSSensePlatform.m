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
#import "CSSensorConstants.h"
//#import "BloodPressureSensor.h"

@import DSESwift;

NSString * const kCSDATA_TYPE_JSON = @"json";
NSString * const kCSDATA_TYPE_INTEGER = @"integer";
NSString * const kCSDATA_TYPE_FLOAT = @"float";
NSString * const kCSDATA_TYPE_STRING = @"string";
NSString * const kCSDATA_TYPE_BOOL = @"bool";


static CSSensorStore* sensorStore;
__weak id <CSLocationPermissionProtocol> locationPermissionDelegate;

@implementation CSSensePlatform {
    
}

+ (void) initializeWithApplicationKey: (NSString*) applicationKey {
    [CSSensorStore sharedSensorStore].sender.applicationKey = applicationKey;
    
    [self initialize];
    [[CSSensorStore sharedSensorStore] start];
}

+ (void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initializeOnce];
    });

}

+ (void) initializeOnce; {
    
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
    //[CSSensePlatform addDataPointForSensor:@"app_info" displayName:@"Application Information" description:appIdentifier dataType:kCSDATA_TYPE_JSON jsonValue:data timestamp:[NSDate date]];
    
    // listen for notifications from the location provider indicating it has obtained permissions from the user
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationPermissionGranted:) name:[CSSettings permissionGrantedForProvider:kCSLOCATION_PROVIDER] object:nil];
    // listen for notifications from the location provider indicating permission was denied by the user
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationPermissionDenied:) name:[CSSettings permissionDeniedForProvider:kCSLOCATION_PROVIDER] object:nil];

}

+ (NSArray*) availableSensors {
    return [CSSensorStore sharedSensorStore].sensors;
}

+ (BOOL) isAvailableSensor:(NSString*) sensorID {
    NSArray *sensors = [CSSensePlatform availableSensors];
    for (CSSensor *sensor in sensors) {
        if ([sensor.name isEqualToString:sensorID]) {
            return YES;
        }
    }
    
    return NO;
}

+ (void) willTerminate {
    [[CSSensorStore sharedSensorStore] forceDataFlushWithSuccessCallback:nil failureCallback:^(NSError* error){NSLog(@"flush data failed");}];
}

+ (void) flushData {
    [[CSSensorStore sharedSensorStore] forceDataFlushWithSuccessCallback:nil failureCallback:^(NSError* error){NSLog(@"flush data failed");}];
}

+ (void) flushDataWithSuccessCallback: (void(^)()) successCallback failureCallback:(void(^)(NSError*)) failureCallback {
    [[CSSensorStore sharedSensorStore] forceDataFlushWithSuccessCallback:successCallback failureCallback:failureCallback];
}

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password {
    
    NSError* error = nil;
    return [[CSSensorStore sharedSensorStore] loginWithUser:user andPassword:password completeHandler:^{} failureHandler:^{}andError:&error];
}

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password completeHandler:(void (^)()) successHandler failureHandler:(void (^)()) failureHandler andError:(NSError **) error {

    return [[CSSensorStore sharedSensorStore] loginWithUser:user andPassword:password completeHandler:successHandler failureHandler:failureHandler andError:error];
}

+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash {
    NSError* error;
    return [[self class] loginWithUser:user andPasswordHash:passwordHash andError:&error];
}

+ (BOOL) loginWithUser:(NSString*) user andPasswordHash:(NSString*) passwordHash andError:(NSError **) error {
    [[CSSettings sharedSettings] setLogin:user withPasswordHash:passwordHash];

    return [[CSSensorStore sharedSensorStore] loginWithUser:user andPassword:passwordHash completeHandler:^{} failureHandler:^{} andError:error];
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
    [[CSSensorStore sharedSensorStore] logout];
}

+ (BOOL) isLoggedIn {
    return [[CSSensorStore sharedSensorStore].sender isLoggedIn];
}

+ (NSString*) getSessionId {
    NSString* sessionId = [[CSSensorStore sharedSensorStore].sender getSessionId];
    
    if (sessionId == nil) {
        NSString* user = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
        NSString* hash = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword];
        if (user != nil && hash != nil) {
            [CSSensePlatform loginWithUser:user andPasswordHash:hash];
            sessionId = [[CSSensorStore sharedSensorStore].sender getSessionId];
        }
    }
    return sessionId;
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
    if (error) {
        NSLog(@"Error while serializing jsonValue to NSData. Error:%@", error);
    }
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


+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName description:(NSString *)description device:(NSDictionary*)device dataType:(NSString*)dataType stringValue:(id)value timestamp:(NSDate*)timestamp {
    
    if (displayName == nil)
        displayName = sensorName;
    if (description == nil)
        description = sensorName;
    
    //create sensor
    CSDynamicSensor* sensor = [[CSDynamicSensor alloc] initWithName:sensorName displayName:displayName deviceType:description dataType:dataType fields:nil device:device];

    //commit value
    id jsonValue = value;
    if (value != nil && [value isKindOfClass:[NSString class]]){
        NSString* stringValue = (NSString*) value;
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.decimalSeparator = @".";
        if(dataType == kCSDATA_TYPE_FLOAT){
            jsonValue = [formatter numberFromString:stringValue];
        }else if (dataType == kCSDATA_TYPE_INTEGER){
            jsonValue = [formatter numberFromString:stringValue];
        }else if (dataType == kCSDATA_TYPE_STRING){
            jsonValue = stringValue;
        }else if (dataType == kCSDATA_TYPE_JSON){
            NSError *error = nil;
            jsonValue = [NSJSONSerialization JSONObjectWithData:[value dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
            if (error) {
                NSLog(@"Error while serializing jsonValue to NSData. Error:%@", error);
            }
        }
    }

    if (jsonValue == nil) {
        NSLog(@"Error during adding DataPoint. Invalid value type.");
    }
    
    [sensor commitValue:jsonValue withTimestamp:timestamp];
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

//+ (NSArray*) getDataForSensor:(NSString *)name onlyFromDevice:(bool)onlyFromDevice nrLastPoints:(NSInteger)nrLastPoints {
//    
//}

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

+ (NSString*) getDeviceId {
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

+ (void) requestLocationPermissionWithDelegate: (id <CSLocationPermissionProtocol>) delegate {
    locationPermissionDelegate = delegate;
    [sensorStore requestLocationPermission];
}

+ (void) locationPermissionGranted:(NSNotification*) notification {
    // make sure the delegate implements the selector, so we dont crash the app here.
    if ([locationPermissionDelegate respondsToSelector:@selector(locationPermissionGranted)]) {
        [locationPermissionDelegate locationPermissionGranted];
    } else {

    }
}

+ (void) locationPermissionDenied:(NSNotification*) notification {
    // make sure the delegate implements the selector, so we dont crash the app here.
    if ([locationPermissionDelegate respondsToSelector:@selector(locationPermissionDenied)]) {
        [locationPermissionDelegate locationPermissionDenied];
    } else {
        
    }
}

+ (CLAuthorizationStatus) locationPermissionState; {
    // TODO: refactor so we don't need all this indirection
    return [sensorStore locationPermissionState];
}



@end