//
//  JumpDetector.h
//  sense platform library
//
//  Created by Pim Nijdam on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMotion/CoreMotion.h"
#import "Sensor.h"

@interface JumpSensor : Sensor
- (void) pushDeviceMotion: (CMDeviceMotion*) motion;
@end