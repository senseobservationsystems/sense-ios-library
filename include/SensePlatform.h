//
//  sense_platform_library.h
//  sense platform library
//
//  Created by Pim Nijdam on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//Include all sensors
#import "AccelerationSensor.h"
#import "AccelerometerSensor.h"
#import "BatterySensor.h"
#import "CallSensor.h"
#import "CompassSensor.h"
#import "ConnectionSensor.h"
#import "LocationSensor.h"
#import "MiscSensor.h"
#import "NoiseSensor.h"
#import "OrientationSensor.h"
#import "OrientationStateSensor.h"
#import "PreferencesSensor.h"
#import "RotationSensor.h"

extern NSString * const kSENSEPLATFORM_DATA_TYPE_JSON;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_INTEGER;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_FLOAT;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_STRING;

@interface SensePlatform : NSObject
+ (void) initialize;
+ (NSArray*) availableSensors;
+ (void) willTerminate;
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password;
+ (BOOL) registerhUser:(NSString*) user withPassword:(NSString*) password;
+ (void) applyIVitalitySettings;
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp;
@end
