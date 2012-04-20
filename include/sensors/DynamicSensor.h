//
//  DynamicSensor.h
//  fiqs
//
//  Created by Pim Nijdam on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Sensor.h"

@interface DynamicSensor : Sensor {
    NSString* sensorName;
    NSString* displayName;
    NSString* deviceType;
    NSString* dataType;
}
- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType;
- (void) commitValue:(NSString*)value withTimestamp:(NSString*)timestamp;
@end

