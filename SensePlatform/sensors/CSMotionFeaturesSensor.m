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

#import "CSMotionFeaturesSensor.h"

NSString* accelerationAvg = @"acceleration average";
NSString* accelerationStddev = @"acceleration stddev";
NSString* accelerationKurtosis = @"acceleration kurtosis";
NSString* rotationAvg = @"rotation average";
NSString* rotationStddev = @"rotation stddev";
NSString* rotationKurtosis = @"rotation kurtosis";

@implementation CSMotionFeaturesSensor
- (NSString*) name {return kCSSENSOR_MOTION_FEATURES;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"float", accelerationAvg,
							@"float", accelerationStddev,
							@"float", accelerationKurtosis,
							@"float", rotationAvg,
							@"float", rotationStddev,
							@"float", rotationKurtosis,
							nil];
	//make string, as per spec
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"json", @"data_type",
			json, @"data_structure",
			nil];
}

@end
