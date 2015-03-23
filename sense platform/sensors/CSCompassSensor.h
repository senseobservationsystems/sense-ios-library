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

extern NSString* magneticHeadingKey;
extern NSString* devXKey;
extern NSString* devYKey;
extern NSString* devZKey;
extern NSString* accuracyKey;

/**
 Sensor that stores compass data coming from the magnetometer sensor in the phone.
 
 ___WARNING___ 
 Data collection for this sensor is currently not implemented. This is still to be done in the CSSpatialProvider class.
 
 See also Apple's CMDeviceMotion.h for more information.
 
 ___JSON output value format___
 
	 {
		 "heading": FLOAT;
		 "x": FLOAT;
		 "y": FLOAT;
		 "z": FLOAT;
		 "accurcy": FLOAT;
	 }
	 
 */
@interface CSCompassSensor : CSSensor {
}

@end
