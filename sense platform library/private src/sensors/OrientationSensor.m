//
//  MotionSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 2/28/11.
//  Copyright 2011 Almende. All rights reserved.
//
#import <CoreMotion/CMAccelerometer.h>
#import <CoreMotion/CMMotionManager.h>
#import "OrientationSensor.h"
#import "JSON.h"


@implementation OrientationSensor

//constants
NSString* attitudeRollKey = @"roll";
NSString* attitudePitchKey = @"pitch";
NSString* attitudeYawKey = @"azimuth";

static const double G = 9.81;


- (NSString*) name {return @"orientation";}
- (NSString*) deviceType {return [self name];}
//TODO: check for availability
+ (BOOL) isAvailable {
    CMMotionManager* motionManager = [[CMMotionManager alloc] init];
	BOOL available = motionManager.deviceMotionAvailable;
	return available;
}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							//attitude
							@"float", attitudeRollKey,
							@"float", attitudePitchKey,
							@"float", attitudeYawKey,
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
