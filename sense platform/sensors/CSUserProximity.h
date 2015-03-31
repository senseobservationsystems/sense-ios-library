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
 Sensor storing proximity data. Currently stores whether the user is close to the device or not. This sensor is event based and only stores data upon changes.
 
 ___JSON output value format___
 
	"value": STRING; //"true", "false"
 */
@interface CSUserProximity : CSSensor {

}

/**
 *  Stores new value when state changes.
 *
 *  @param notification Notification when state changes containing information about the new state.
 */
- (void) commitUserProximity:(NSNotification*) notification;

@end
