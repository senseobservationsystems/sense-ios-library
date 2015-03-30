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


/**
 Sensor that stores derivate of the motion data in the form of motion energy; i.e., a measure of the total amount of motion that occured over a specific time frame. 
 
 ___WARNING___ Since no time interval can be specified, this is currently implement as the average energy over all samples collected in a polling action.
 
 ___JSON output value format___
 
	"value": FLOAT;
 
 */
@interface CSMotionEnergySensor : CSSensor

@end
