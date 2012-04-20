//
//  Sensor.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sensor.h"
#import "Settings.h"


@implementation Sensor
@synthesize dataStore;
@synthesize isEnabled;

//constants
- (NSString*) name {return @"";}
- (NSString*) displayName {return [self name];}
- (NSString*) deviceType {return @"";}

//check name and device_type (as per senseApp)
- (BOOL) matchesDescription:(NSDictionary*) description {
	if (description == nil)
		return NO;
	//check name
	NSString* dName = [description valueForKey:@"name"];
	 if (dName == nil || ([dName caseInsensitiveCompare:[self name]] != 0))
		 return NO;
	//check device_type
	NSString* dType = [description valueForKey:@"device_type"];
	if (dType == nil || ([dType caseInsensitiveCompare:[self deviceType]] != 0))
		return NO;
	
	//passed all checks, hence the description matches
	return YES;
}

- (NSDictionary*) sensorDescription {return nil;}
+ (BOOL) isAvailable {return NO;}

- (id) init {
	self = [super init];
	 if (self) {
		 //register for enable changed notification
		 [[NSNotificationCenter defaultCenter] addObserver:self
												  selector:@selector(enabledChanged:)
													  name:[Settings enabledChangedNotificationNameForSensor:[self class]] object:nil];
	 }
	 return self;
}

- (void) enabledChanged: (id) notification {
	self.isEnabled = [[notification object] boolValue];
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString*) sensorId {
    return [NSString stringWithFormat:@"%@", [self name]];
}

@end
