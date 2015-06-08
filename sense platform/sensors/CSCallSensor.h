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
#import <CoreTelephony/CTCallCenter.h>

/**
 Sensor that stores the call state information. This sensor is event based, it stores a new data with each call that starts or ends or comes in. Ringing state indicates the user receiving a call, whereas dialing state indicates user making a call. It does not store caller information which is not available because of privacy reasons.
 
 ___JSON output value format___
 
	{
		"state": STRING; //"idle", "ringing", "dialing", "calling"
	}
 */
@interface CSCallSensor : CSSensor {
	CTCallCenter* callCenter;
}

@end
