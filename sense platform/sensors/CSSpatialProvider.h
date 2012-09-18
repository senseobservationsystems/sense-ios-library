//
//  SpatialProvider.h
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "CSCompassSensor.h"
#import "CSOrientationSensor.h"
#import "CSAccelerometerSensor.h"
#import "CSAccelerationSensor.h"
#import "CSRotationSensor.h"
#import "CSJumpSensor.h"

@interface CSSpatialProvider : NSObject {
}

- (id) initWithCompass:(CSCompassSensor*)compass orientation:(CSOrientationSensor*)orientation accelerometer:(CSAccelerometerSensor*)accelerometer acceleration:(CSAccelerationSensor*)acceleration rotation:(CSRotationSensor*)rotation jumpSensor:(CSJumpSensor*) jumpSensor;
@end
