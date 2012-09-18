//
//  MiscSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 5/24/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "CSMiscSensor.h"
#import "CSJSON.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"

static NSString* variableKey = @"variable";
static NSString* valueKey = @"value";

@implementation CSMiscSensor
- (NSString*) name {return kCSSENSOR_MISC;}
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
			nil];}

- (id) init {
	self = [super init];
	if (self) {
		//register for proximity notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(proximityStateChanged:)
													 name:UIDeviceProximityStateDidChangeNotification object:nil];
		//register for background/foreground notifications
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(becameActive:)
													 name:UIApplicationDidBecomeActiveNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(becomesInactive:)
													 name:UIApplicationWillResignActiveNotification object:nil];
	}
	return self;
}

- (void) proximityStateChanged:(NSNotification*) notification {
	//get proximity infomation
	NSString* proximityState = [[UIDevice currentDevice] proximityState] ? @"true": @"false";
		
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"proximity", variableKey,
									proximityState, valueKey,
									nil];
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp, @"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (void) becameActive:(NSNotification*) notification {	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"application state", variableKey,
									@"active", valueKey,
									nil];
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (void) becomesInactive:(NSNotification*) notification {	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									@"application state", variableKey,
									@"inactive", valueKey,
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
	
	NSLog(@"Enabling miscalleneous sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end
