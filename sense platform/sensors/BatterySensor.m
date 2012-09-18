//
//  BatterySensor.m
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "BatterySensor.h"
#import "CSJSON.h"
#import <UIKit/UIKit.h>
#import "DataStore.h"


@implementation BatterySensor
//constants
static NSString* stateKey = @"status";
static NSString* levelKey = @"level";

- (NSString*) name {return kSENSOR_BATTERY;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"float", levelKey,
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
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
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
