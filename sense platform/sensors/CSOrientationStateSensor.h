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
#import "CSSensor.h"

/**
 Sensor that stores the state of the orientation of the phone. This sensor is event based, it stores a new data with each change in the value. Note that this orientation state does not necessarily correspond to the UI state, it is the state of the device itself.
 
 ___JSON output value format___
 
	"value": STRING; //"face up", "face down", "portrait", "portrait upside down", "landscape left", "landscape right", "unknown"
 
 */
@interface CSOrientationStateSensor : CSSensor {
	
}

/** Store new orientation state after a change notification
 @param notification Notification containing the new state information.
 */
- (void) commitOrientation:(NSNotification*) notification;


@end
