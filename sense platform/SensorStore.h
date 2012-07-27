//
//  sensorStore.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataStore.h"
#import "Sender.h"
#import "Sensor.h"

extern NSString* const kMotionData;

@interface SensorStore : NSObject <DataStore> {
}

@property (readonly, retain) NSArray* allAvailableSensorClasses;
@property (readonly, retain) NSArray* sensors;
@property (readonly, retain) Sender* sender;


+ (SensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;
- (void) setSyncRate: (int) newRate;
- (void) addSensor:(Sensor*) sensor;
- (NSDictionary*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk (not impemented)
 * - delete
 */
- (void) forceDataFlush;
- (void) generalSettingChanged: (NSNotification*) notification;


@end
