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

/** Sensor that can be used to store all the settings. Whenever a setting is changed it stores a new datapoint. 
 
 This sensor is typically not being used anymore. It has been replaced by the local file in which settings are stored.
 
 */
@interface CSPreferencesSensor : CSSensor {

}

/** Store new settings value.
 @param notification Notification containing the new settings value.
 */
- (void) commitPreference:(NSNotification*) notification;

@end
