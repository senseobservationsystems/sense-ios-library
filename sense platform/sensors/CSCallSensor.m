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

#import "CSCallSensor.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "CSDataStore.h"
#import "Formatting.h"


@implementation CSCallSensor

//constants
static NSString* stateKey = @"state";

static NSString* incomingCall = @"ringing";
static NSString* dialing = @"dialing";
static NSString* connected = @"calling";
static NSString* disconnected = @"idle";


- (NSString*) name {return kCSSENSOR_CALL;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", stateKey,
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
		callCenter = [[CTCallCenter alloc] init];
	}
	return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	NSLog(@"%@ call sensor (id=%@)", enable ? @"Enabling":@"Disabling", self.sensorId);
	CSCallSensor* __block selfRef = self;
	if (enable) {
		callCenter.callEventHandler = ^(CTCall* inCTCall) {
			NSLog(@"%@: %@",inCTCall.callID, inCTCall.callState);
			NSString* callState=@"unknown";
			if ([inCTCall.callState isEqualToString:CTCallStateDialing])
				callState = dialing;
			else if ([inCTCall.callState isEqualToString:CTCallStateIncoming])
				callState = incomingCall;
			else if ([inCTCall.callState isEqualToString:CTCallStateConnected])
				callState = connected;
			else if ([inCTCall.callState isEqualToString:CTCallStateDisconnected])
				callState = disconnected;

			
			NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											callState, stateKey,
											nil];
			
			NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
			
			NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
												newItem, @"value",
												timestamp,@"date",
												nil];
			[selfRef.dataStore commitFormattedData:valueTimestampPair forSensorId:selfRef.sensorId];
			
		};
	} else {
		callCenter.callEventHandler = nil;
	}
	
	isEnabled = enable;
}

-(void) dealloc {
	self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end