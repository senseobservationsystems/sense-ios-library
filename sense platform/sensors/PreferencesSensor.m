//
//  PreferencesSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 5/18/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "PreferencesSensor.h"
#import "CSJSON.h"
#import "Settings.h"
#import <UIKit/UIKit.h>
#import "DataStore.h"

@implementation PreferencesSensor
//constants
static NSString* variableKey = @"variable";
static NSString* valueKey = @"value";

- (NSString*) name {return kSENSOR_PREFERENCES;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", variableKey,
							@"string", valueKey,
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
		//register for preferences notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitPreference:)
													 name:anySettingChangedNotification object:nil];
	}
	return self;
}

- (void) commitPreference:(NSNotification*) notification {
	Setting* setting = notification.object;
	
    /*
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									setting.name, variableKey,
									setting.value, valueKey,
									nil];
     */
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									setting.value, setting.name,
									nil];
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling battery sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	[UIDevice currentDevice].batteryMonitoringEnabled = enable;
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
