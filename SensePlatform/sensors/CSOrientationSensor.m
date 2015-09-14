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
#import <CoreMotion/CMAccelerometer.h>
#import <CoreMotion/CMMotionManager.h>
#import "CSOrientationSensor.h"


@implementation CSOrientationSensor

//constants
NSString* attitudeRollKey = @"roll";
NSString* attitudePitchKey = @"pitch";
NSString* attitudeYawKey = @"azimuth";

- (NSString*) name {return kCSSENSOR_ORIENTATION;}
- (NSString*) deviceType {return [self name];}
//TODO: check for availability
+ (BOOL) isAvailable {
    CMMotionManager* motionManager = [[CMMotionManager alloc] init];
	BOOL available = motionManager.deviceMotionAvailable;
	return available;
}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							//attitude
							@"float", attitudeRollKey,
							@"float", attitudePitchKey,
							@"float", attitudeYawKey,
							nil];
	//make string, as per spec
    NSError* error = nil;
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

- (id) init {
	self = [super init];
	if (self) {
	}
	
	return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	NSLog(@"%@ %@ sensor (id=%@).", enable ? @"Enabling":@"Disabling", [self class], self.sensorId);
	isEnabled = enable;
}


- (void) dealloc {
	self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
