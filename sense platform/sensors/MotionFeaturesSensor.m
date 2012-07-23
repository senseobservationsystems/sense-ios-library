//
//  MotionFeaturesSensor.m
//  sense platform library
//
//  Created by Pim Nijdam on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MotionFeaturesSensor.h"
#import "JSON.h"

NSString* accelerationAvg = @"acceleration average";
NSString* accelerationStddev = @"acceleration stddev";
NSString* accelerationKurtosis = @"acceleration kurtosis";
NSString* rotationAvg = @"rotation average";
NSString* rotationStddev = @"rotation stddev";
NSString* rotationKurtosis = @"rotation kurtosis";

@implementation MotionFeaturesSensor
- (NSString*) name {return kSENSOR_MOTION_FEATURES;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"float", accelerationAvg,
							@"float", accelerationStddev,
							@"float", accelerationKurtosis,
							@"float", rotationAvg,
							@"float", rotationStddev,
							@"float", rotationKurtosis,
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

@end
