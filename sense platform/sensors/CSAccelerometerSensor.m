//
//  AccelerometerSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "CSAccelerometerSensor.h"
#import "CSJSON.h"


//constants
NSString* CSaccelerationXKey = @"x-axis";
NSString* CSaccelerationYKey = @"y-axis";
NSString* CSaccelerationZKey = @"z-axis";

@implementation CSAccelerometerSensor


- (NSString*) name {return kCSSENSOR_ACCELEROMETER;}
- (NSString*) deviceType {return [self name];}
//TODO: check for availability
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							//acceleration
							@"float", CSaccelerationXKey,
							@"float", CSaccelerationYKey,
							@"float", CSaccelerationZKey,
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
	}
	
	return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	NSLog(@"%@ %@ sensor (id=%@).", enable ? @"Enabling":@"Disabling", [self class], self.sensorId);
	isEnabled = enable;
}


- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
