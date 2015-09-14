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

#import "CSBatterySensor.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"


@implementation CSBatterySensor
//constants
static NSString* stateKey = @"status";
static NSString* levelKey = @"level";

- (NSString*) name {return kCSSENSOR_BATTERY;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"float", levelKey,
							@"string", stateKey,
							nil];
	//make string, as per spec
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"json", @"data_type",
			jsonString, @"data_structure",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		//register for battery notifications, notifications will be received at the current thread
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitBatteryState:)
													 name:UIDeviceBatteryLevelDidChangeNotification object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitBatteryState:)
													 name:UIDeviceBatteryStateDidChangeNotification object:nil];
	}
	return self;
}

- (void) commitBatteryState:(NSNotification*) notification {
    if (isEnabled) {
	//get battery infomation
	UIDevice* currentDevice = [UIDevice currentDevice];
	NSString* batteryState = @"unknown";
	//convert state to string:
	switch ([currentDevice batteryState]) {
		case UIDeviceBatteryStateUnknown:
			batteryState = @"unknown";
			break;
		case UIDeviceBatteryStateUnplugged:
			batteryState = @"discharging";
			break;
		case UIDeviceBatteryStateCharging:
			batteryState = @"charging";
			break;
		case UIDeviceBatteryStateFull:
			batteryState = @"full";
			break;
	}
	//battery level as percentage
	NSNumber* batteryLevel = [NSNumber numberWithFloat:[currentDevice batteryLevel] * 100];
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									batteryLevel, levelKey,
									batteryState, stateKey,
									nil];
	
	NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
    }
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ battery sensor (id=%@):", self.sensorId, enable ? @"Enabling":@"Disabling");
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	isEnabled = enable;
    
    if (enable) {
        //as this one is only committed when it changes, commit current value
        [self commitBatteryState:nil];
    }
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
