#import "SensePlatform.h"
#import "SensorStore.h"
#import "Settings.h"
#import "DynamicSensor.h"

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

+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password {
    [[Settings sharedSettings] setLogin:user withPassword:password];
    return [sensorStore.sender login];
}

+ (BOOL) registerhUser:(NSString*) user withPassword:(NSString*) password {

    NSString* error;
    BOOL succes =  [sensorStore.sender registerUser:user withPassword:password error:&error];
    if (succes)
            [[Settings sharedSettings] setLogin:user withPassword:password];
    return succes;
        
}

+ (void) applyIVitalitySettings {
    Settings* settings = [Settings sharedSettings];
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingPollInterval value:@"60"];
    [settings setSettingType:kSettingTypeLocation setting:kLocationSettingAccuracy  value:@"10000"];
    [settings setSettingType:kSettingTypeAmbience setting:kAmbienceSettingInterval  value:@"60"];
    
    [settings setSensor:[LocationSensor class] enabled:YES];
    [settings setSensor:[NoiseSensor class] enabled:YES];
    [settings setSensor:[AccelerationSensor class] enabled:YES];
    [settings setSensor:[AccelerometerSensor class] enabled:YES];
    [settings setSensor:[OrientationSensor class] enabled:YES];
    [settings setSensor:[RotationSensor class] enabled:YES];
    
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingSenseEnabled value:kSettingYES];
}

+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp {
    //create sensor
    DynamicSensor* sensor = [[DynamicSensor alloc] initWithName:sensorName displayName:displayName deviceType:deviceType dataType:dataType];
    //add sensor to the sensor store
    [sensorStore addSensor:sensor];
    //commit value
    [sensor commitValue:value withTimestamp:[NSString stringWithFormat:@"%.3f",timestamp]];
}
@end