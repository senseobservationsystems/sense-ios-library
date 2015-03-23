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
#import <CoreMotion/CoreMotion.h>
#import "CSCompassSensor.h"
#import "CSOrientationSensor.h"
#import "CSAccelerometerSensor.h"
#import "CSAccelerationSensor.h"
#import "CSRotationSensor.h"
#import "CSJumpSensor.h"


/** Class that provides data for the following sensors:
	
	- Compass sensor (currently not implemented)
	- Orientation sensor
	- Accelerometer sensor
	- Acceleration sensor
	- Rotation sensor
	- Jump sensor (legacy, should probably be avoided)
 
 It polls at fixed intervals to collect data and subseuqently stores that data in the individual sensors. The settings below can be used to further specify its behavior.
 
 ___Spatial settings___
 
 - <code>kCSSpatialSettingInterval</code><br> Interval between sampling spatial (motion) data. Specified in seconds, by default set to 60 seconds.
 - <code>kCSSpatialSettingFrequency</code><br> Sample frequency of the motion data sampling. Specified in Herz. By default set to 50 Hz. Note that this is limited by hardware potential.
 - <code>kCSSpatialSettingNrSamples</code><br> Number of samples to collect for each sampling cycle. Specified in numbers of samples. By default set to 150 samples, this means 3 seconds of sampled data when using the standard of 50 Hz as sampling frequency.
 
 */
@interface CSSpatialProvider : NSObject {
}


/** Init function taking the different sensors in which to store the data
 @param compass
 @param orientation
 @param accelerometer
 @param acceleration
 @param rotation
 @param jumpSensor
 */
- (id) initWithCompass:(CSCompassSensor*)compass orientation:(CSOrientationSensor*)orientation accelerometer:(CSAccelerometerSensor*)accelerometer acceleration:(CSAccelerationSensor*)acceleration rotation:(CSRotationSensor*)rotation jumpSensor:(CSJumpSensor*) jumpSensor;

/** Poll the motion sensors once **/
- (void) poll;

@end
