//
//  OrientationSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 2/28/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "OrientationStateSensor.h"
#import <UIKit/UIKit.h>
#import "DataStore.h"

@implementation OrientationStateSensor

- (NSString*) name {return @"device orientation";}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}


- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"string", @"data_type",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		//register for proximity notification
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(commitOrientation:)
													 name:UIDeviceOrientationDidChangeNotification object:nil];
	}
	return self;
}

- (void) commitOrientation:(NSNotification*) notification {
	//get orientation infomation
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	//convert to string
	NSString* orientationString = @"";
	switch (orientation) {
		case UIDeviceOrientationFaceUp:
			orientationString = @"face up";
			break;
		case UIDeviceOrientationFaceDown:
			orientationString = @"face down";
			break;
		case UIDeviceOrientationPortrait:
			orientationString = @"portrait";
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			orientationString = @"portrait upside down";
			break;
		case UIDeviceOrientationLandscapeLeft:
			orientationString = @"landscape left";
			break;
		case UIDeviceOrientationLandscapeRight:
			orientationString = @"landscape right";
			break;
		case UIDeviceOrientationUnknown:
			orientationString = @"unknown";
			break;
	}
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										orientationString, @"value",
										timestamp,@"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling orientation sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	} else {
		[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	}

	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end
