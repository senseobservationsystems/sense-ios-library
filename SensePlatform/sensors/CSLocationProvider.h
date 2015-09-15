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
 Provider that handles all the location related tracking. Receives location points and visits from the OS and processes them.
 
 It uses two sensors: CSLocationSensor and CSVisitsSensor for storing location data and visit data respectively.
 
 Note that if you don't need location information this provider is still necessary for running the app in the background. To make sure it uses the least amount of battery when running in the background you want to increase the desired accuracy and the auto pausing feature (both can be found in CSSettings.h).
 
 ___Location settings___
 
 - <code>kCSLocationSettingAccuracy</code><br> Accuracy with which iOS will detect location data points. Lower values will provide higher accuracy but will also use more battery. Apple generally distinguishes three levels: GPS, WiFi, Cell tower. GPS is the most accurate (< 1 meter) but uses a lot of battery power. Wifi is accurate at around ~100 meters and uses less battery. Cell tower is accurate at about ~2 km and uses the least amount of battery. Setting is specified in meters (as a String). The default value is set to 100 meters.
 - <code>kCSLocationSettingMinimumDistance</code><br> Minimum distance used before getting a location update. When not specified it updates whenever iOS deems it relevant to update, this is recommended. Specified in meters. Uses the standard iOS functionality. Not set by default.
 - <code>kCSLocationSettingCortexAutoPausing</code><br>	Setting for automatically pausing location updates for three minutes after a new datapoint has come in, this might save battery life. Values are <code>kCSSettingYes</code> or <code>kCSSettingNo</code>. Disabled by default.

___Warning___
To be able to use location sensing you need to add to your `info.plist` file the `UIBackgroundModes`:
 
 - "App registers for location updates"
 - and if you are using the noise sensor also add "App plays audio".
 
 Note that from iOS 8 onwards you will also need to set NSLocationAlwaysUsageDescription in Info.plist because otherwise the app will not ask for permission. This is a text that is displayed in the dialog box asking the user for permission to use the location even when running in the backgroud.
 */
@interface CSLocationProvider : NSObject <CLLocationManagerDelegate>{
	BOOL isEnabled;
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

/** 
 This function return the current authorization state for location updates.

 @return CLAuthorizationStatus current authorization status of the CLLocationManager
 */
- (CLAuthorizationStatus) permissionState;

/**
 Function to make the LocationProvider obtain permission. Once the user either grants or denies permissions, this will generate a notification of that event.
 */
- (void) requestPermission;

@end
