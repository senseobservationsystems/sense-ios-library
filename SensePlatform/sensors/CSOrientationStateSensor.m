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

#import "CSOrientationStateSensor.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"
@implementation CSOrientationStateSensor

- (NSString*) name {return @"device orientation";}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}


- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"string", @"data_type",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		//register for proximity notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitOrientation:)
													 name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	return self;
}

- (void) commitOrientation:(NSNotification*) notification {
	//get orientation infomation
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	//convert to string
	NSString* orientationString = @"";
	switch (orientation) {
		case UIDeviceOrientationFaceUp:
			orientationString = @"face up";
			break;
		case UIDeviceOrientationFaceDown:
			orientationString = @"face down";
			break;
		case UIDeviceOrientationPortrait:
			orientationString = @"portrait";
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orientationString = @"portrait upside down";
			break;
		case UIDeviceOrientationLandscapeLeft:
			orientationString = @"landscape left";
			break;
		case UIDeviceOrientationLandscapeRight:
			orientationString = @"landscape right";
			break;
		case UIDeviceOrientationUnknown:
			orientationString = @"unknown";
			break;
	}
	
	NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										orientationString, @"value",
										timestamp,@"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling orientation sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	} else {
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}

	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end
