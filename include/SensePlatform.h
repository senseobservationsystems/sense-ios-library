//
//  sense_platform_library.h
//  sense platform library
//
//  Created by Pim Nijdam on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//Include all sensors
#include "Sensor.h"
#include "SensorIds.h"

extern NSString * const kSENSEPLATFORM_DATA_TYPE_JSON;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_INTEGER;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_FLOAT;
extern NSString * const kSENSEPLATFORM_DATA_TYPE_STRING;

extern NSString* const kNewSensorDataNotification;

typedef enum {BPM_SUCCES=0, BPM_CONNECTOR_NOT_PRESENT, BPM_NOT_FOUND, BPM_UNAUTHORIZED, BPM_OTHER_ERROR} BpmResult;
typedef void(^bpmCallBack)(BpmResult result, NSInteger newOkMeasurements, NSInteger newFailedMeasurements, NSDate* latestMeasurement);

@interface SensePlatform : NSObject
+ (void) initialize;
+ (NSArray*) availableSensors;
+ (void) willTerminate;
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password;
+ (BOOL) registerhUser:(NSString*) user withPassword:(NSString*) password;
+ (void) applyIVitalitySettings;
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp;
+ (void) synchronizeWithBloodPressureMonitor:(bpmCallBack) callback;
@end