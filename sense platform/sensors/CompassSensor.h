//
//  CompassSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sensor.h"

extern NSString* magneticHeadingKey;
extern NSString* devXKey;
extern NSString* devYKey;
extern NSString* devZKey;
extern NSString* accuracyKey;

@interface CompassSensor : Sensor {
}

@end
