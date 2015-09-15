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

#import "CSUserProximity.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"


@implementation CSUserProximity

- (NSString*) name {return @"user proximity";}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"bool", @"data_type",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		//register for proximity notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitUserProximity:)
													 name:UIDeviceProximityStateDidChangeNotification object:nil];
	}
	return self;
}

- (void) commitUserProximity:(NSNotification*) notification {
	//get proximity infomation
	NSString* proximityState = [[UIDevice currentDevice] proximityState] ? @"true": @"false";
	
	NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										proximityState, @"value",
										timestamp,@"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling user proximity sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	[UIDevice currentDevice].proximityMonitoringEnabled = enable;
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end
