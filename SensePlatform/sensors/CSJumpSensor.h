/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import <Foundation/Foundation.h>
#import "CoreMotion/CoreMotion.h"
#import "CSSensor.h"


/** Sensor to store jump data. This is a legacy sensor that should be used carefully. */
@interface CSJumpSensor : CSSensor

/**
 *   New values are stored based on CMDeviceMotion and CMMotionManager objects that contain the jump data.
 *
 *  @param motion        Device motion object containing the jump data.
 *  @param motionManager Motion manager object which gathered the motion.
 */
- (void) pushDeviceMotion: (CMDeviceMotion*) motion andManager:(CMMotionManager*) motionManager;
@end
