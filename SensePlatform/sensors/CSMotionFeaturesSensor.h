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
extern NSString* accelerationAvg;
extern NSString* accelerationStddev;
extern NSString* accelerationKurtosis; // is not being used right now
extern NSString* rotationAvg;
extern NSString* rotationStddev;
extern NSString* rotationKurtosis; // is not being used right now

/**
 Sensor that stores several derivates of the motion data in the form of motion energy features; i.e., different aspects of a measure of the total amount of motion that occured over a specific time frame. It currently provides mean, standard deviation and  of the acceleration and rotation of the device.
 
 ___JSON output value format___

	{
		"acceleration average": FLOAT;
 		"acceleration stdev": FLOAT;
 		"rotation average": FLOAT;
 		"rotation stdev": FLOAT;
	}

 */

@interface CSMotionFeaturesSensor : CSSensor

@end
