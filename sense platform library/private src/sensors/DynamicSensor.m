//
//  DynamicSensor.m
//  fiqs
//
//  Created by Pim Nijdam on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DynamicSensor.h"

@implementation DynamicSensor
- (NSString*) name {return sensorName;}
- (NSString*) deviceType {return deviceType;}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			dataType, @"data_type",
			@"", @"data_structure",
			nil];
}

- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType {
	self = [super init];
	if (self) {
        sensorName = name;
        displayName = dispName;
        deviceType = devType;
        dataType = datType;
	}
	return self;
}

- (void) commitValue:(NSString*)value withTimestamp:(NSString*)timestamp {
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										value, @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	NSLog(@"%@ %@ sensor (id=%@)", enable ? @"Enabling":@"Disabling", sensorName, self.sensorId);
	isEnabled = enable;
}

- (NSString*) sensorId {
    return [NSString stringWithFormat:@"%@", sensorName];
}

- (void) dealloc {
    NSLog(@"Deallocating %@", sensorName);
	self.isEnabled = NO;
}

@end
