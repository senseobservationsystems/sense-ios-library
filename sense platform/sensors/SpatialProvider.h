//
//  SpatialProvider.h
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "CompassSensor.h"
#import "OrientationSensor.h"
#import "AccelerometerSensor.h"
#import "AccelerationSensor.h"
#import "RotationSensor.h"
#import "JumpSensor.h"

@interface SpatialProvider : NSObject {
}

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation jumpSensor:(JumpSensor*) jumpSensor;
@end
