//
//  JumpDetector.h
//  sense platform library
//
//  Created by Pim Nijdam on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreMotion/CoreMotion.h"
#import "CSSensor.h"

@interface CSJumpSensor : CSSensor
- (void) pushDeviceMotion: (CMDeviceMotion*) motion andManager:(CMMotionManager*) motionManager;
@end