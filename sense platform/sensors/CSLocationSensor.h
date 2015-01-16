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

#import "CSSensor.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

/**
 Sensor that handles the location tracking
 Receives location points from the OS and processes them.
 
 Note that if you don't need location information this class is still necessary for running the app in the background. To make sure it uses the least amount of battery when running in the background you want to increase the desired accuracy and the auto pausing feature (both can be found in CSSettings.h)
 */
@interface CSLocationSensor : CSSensor <CLLocationManagerDelegate>{

}

@property (assign) BOOL isEnabled;

- (void) setBackgroundRunningEnable:(BOOL) enable;
@end
