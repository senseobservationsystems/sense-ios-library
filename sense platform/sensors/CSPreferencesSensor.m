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

#import "CSPreferencesSensor.h"
#import "CSSettings.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"

@implementation CSPreferencesSensor
//constants
static NSString* variableKey = @"variable";
static NSString* valueKey = @"value";

- (NSString*) name {return kCSSENSOR_PREFERENCES;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", variableKey,
							@"string", valueKey,
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
		//register for preferences notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitPreference:)
													 name:CSanySettingChangedNotification object:nil];
	}
	return self;
}

- (void) commitPreference:(NSNotification*) notification {
	CSSetting* setting = notification.object;
	
    /*
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									setting.name, variableKey,
									setting.value, valueKey,
									nil];
     */
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									setting.value, setting.name,
									nil];
	
	NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ %@ sensor (id=%@)", enable ? @"Enabling":@"Disabling", self.name, self.sensorId);
	[UIDevice currentDevice].batteryMonitoringEnabled = enable;
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
