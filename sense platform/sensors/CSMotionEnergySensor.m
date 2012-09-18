//
//  MotionEnergySensor.m
//  sense platform library
//
//  Created by Pim Nijdam on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CSMotionEnergySensor.h"

@implementation CSMotionEnergySensor
- (NSString*) name {return kCSSENSOR_MOTION_ENERGY;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	//make string, as per spec
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"float", @"data_type",
			nil];
}
@end
