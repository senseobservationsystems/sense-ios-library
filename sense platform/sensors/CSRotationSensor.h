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
 Sensor that stores rotation data. 
 
 See also CMDeviceMotion.h for more information about the data is stored here.
 
 ___JSON output value format___
 
	 {
		 "x-axis": FLOAT;
		 "y-axis": FLOAT;
		 "z-axis": FLOAT;
	 }
	 
 */
@interface CSRotationSensor : CSSensor {

}

@end
