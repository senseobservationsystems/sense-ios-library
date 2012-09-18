//
//  CompassSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "CompassSensor.h"
#import <CoreLocation/CoreLocation.h>
#import "CSJSON.h"


@implementation CompassSensor
//constants
NSString* magneticHeadingKey = @"heading";
NSString* devXKey = @"x";
NSString* devYKey = @"y";
NSString* devZKey = @"z";
NSString* accuracyKey = @"accuracy";

- (NSString*) name {return kSENSOR_COMPASS;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return [CLLocationManager headingAvailable];}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"float", magneticHeadingKey,
							@"float", devXKey,
							@"float", devYKey,
							@"float", devZKey,
							@"float", accuracyKey,
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
