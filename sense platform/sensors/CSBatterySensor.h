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
 Sensor that stores the battery information. This sensor is event based, it stores a new data with each 1% change in the value. When the state is charged, it stores new data regularly.
 
 ___JSON output value format___
 
	 {
		 "level": FLOAT;
		 "status": STRING; //"Unknown", "Discharging", "Charging", "Full"
	 }
 
 */

@interface CSBatterySensor : CSSensor {
	
}

/**
 *  Stores the battery state from a received notification
 *
 *  @param notification Notification object that contains the new battery information.
 */
- (void) commitBatteryState:(NSNotification*) notification;
@end
