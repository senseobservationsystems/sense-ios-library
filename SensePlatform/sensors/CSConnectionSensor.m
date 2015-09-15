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

#import "CSConnectionSensor.h"
#import "CSReachability.h"
#import "CSDataStore.h"
#import "Formatting.h"

@implementation CSConnectionSensor

- (NSString*) name {return kCSSENSOR_CONNECTION_TYPE;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//make string, as per spec
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
		    internetReach = [CSReachability reachabilityForInternetConnection];
		    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	}
	return self;
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	NetworkStatus netStatus = [internetReach currentReachabilityStatus];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"none";  
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"mobile";
            break;
        }
        case ReachableViaWiFi:
        {
			statusString= @"wifi";
            break;
		}
    }
	
	
	NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										statusString, @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	//NSLog(@"Enabling connection type sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		[internetReach startNotifier];
		[self reachabilityChanged:nil];
	} else {
		[internetReach stopNotifier];
	}

	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end