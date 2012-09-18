//
//  callSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 4/19/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "CSCallSensor.h"
#import <CoreTelephony/CTCall.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "CSJSON.h"
#import "CSDataStore.h"


@implementation CSCallSensor

//constants
static NSString* stateKey = @"state";

static NSString* incomingCall = @"ringing";
static NSString* dialing = @"dialing";
static NSString* connected = @"calling";
static NSString* disconnected = @"idle";


- (NSString*) name {return kCSSENSOR_CALL;}
- (NSString*) deviceType {return [self name];}
- (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", stateKey,
							nil];
	//make string, as per spec
	NSString* json = [format JSONRepresentation];
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
			
			NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
			
			NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
												[newItem JSONRepresentation], @"value",
												timestamp,@"date",
												nil];
			[self.dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
			
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