//
//  AccelerationSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 4/28/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <CoreMotion/CoreMotion.h>
#import "CSAccelerometerSensor.h"
#import "CSAccelerationSensor.h"
#import "CSJSON.h"


@implementation CSAccelerationSensor


- (NSString*) name {return kCSSENSOR_ACCELERATION;}
- (NSString*) deviceType {return [self name];}
//TODO: check for availability
+ (BOOL) isAvailable {
	//user acceleration can only be calculated when there is a gyro
	CMMotionManager* motionManager = [[CMMotionManager alloc] init];
	BOOL available = motionManager.deviceMotionAvailable;
	return available;
}

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
