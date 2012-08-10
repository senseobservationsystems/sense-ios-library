//
//  MovingSensor.m
//  sensePlatform
//
//  Created by Pim Nijdam on 9/19/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "MovingSensor.h"


@implementation MovingSensor
- (NSString*) name {return @"moving";}
- (NSString*) deviceType {return [self name];}
//TODO: check for availability
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	//make string, as per spec
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"boolean", @"data_type",
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
