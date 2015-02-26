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

#import <CoreLocation/CoreLocation.h>
#import "CSLocationSensor.h"
#import "CSVisitsSensor.h"

/**
 Provider that handles all the location related tracking
 Receives location points and visits from the OS and processes them.
 
 It uses two sensors: CSLocationSensor and CSVisitsSensor for storing location data and visit data respectively.
 
 Note that if you don't need location information this provider is still necessary for running the app in the background. To make sure it uses the least amount of battery when running in the background you want to increase the desired accuracy and the auto pausing feature (both can be found in CSSettings.h)
 */
@interface CSLocationProvider : NSObject <CLLocationManagerDelegate>{

}

/** 
 * Init method with a location sensor and visits sensor to store the data in
 * @param  lSensor The location sensor
 * @param vSensor The visits sensor
 * @return Returns self
 **/
- (id) initWithLocationSensor: (CSLocationSensor *) lSensor andVisitsSensor: (CSVisitsSensor *) vSensor;


/** This enabled/disables the required monitoring for in the background. It does not affect visits monitoring. In the current implementation, it means the desired accuracy is set and both location updates and significant location updates are started or stopped. Note that if the resulting location points should also be stored, the LocationSensor should be enabled separately.
 **/
@property (assign) BOOL isEnabled;


/**
 *	This enables/disables the required monitoring for in the background. It does not affect visits monitoring. In the current implementation, this means that location updates and significant location updates are enabled/disabaled. Note that when using this function, the desired accuracy should still be handled seperately throught the kCSLocationSettingAccuracy setting. 
 * @warning This function is currently provided for backwards compatibility. It is replaced by isEnabled property.
 * @param enable Setting whether to enable or disable the location monitoring for running in the background
 */
- (void) setBackgroundRunningEnable:(BOOL) enable;
@end
