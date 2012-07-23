//
//  MotionFeaturesSensor.h
//  sense platform library
//
//  Created by Pim Nijdam on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Sensor.h"
extern NSString* accelerationAvg;
extern NSString* accelerationStddev;
extern NSString* accelerationKurtosis;
extern NSString* rotationAvg;
extern NSString* rotationStddev;
extern NSString* rotationKurtosis;

@interface MotionFeaturesSensor : Sensor

@end
