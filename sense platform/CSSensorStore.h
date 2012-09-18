//
//  sensorStore.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSDataStore.h"
#import "CSSender.h"
#import "CSSensor.h"

extern NSString* const kMotionData;

@interface CSSensorStore : NSObject <CSDataStore> {
}

@property (readonly, retain) NSArray* allAvailableSensorClasses;
@property (readonly, retain) NSArray* sensors;
@property (readonly, retain) CSSender* sender;


+ (CSSensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;
- (void) setSyncRate: (int) newRate;
- (void) addSensor:(CSSensor*) sensor;
- (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;
- (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk (not impemented)
 * - delete
 */
- (void) forceDataFlush;
- (void) forceDataFlushAndBlock;
- (void) generalSettingChanged: (NSNotification*) notification;


@end
