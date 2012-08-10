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
	 if (dName == nil || ([dName caseInsensitiveCompare:[self name]] != NSOrderedSame))
		 return NO;
	//check device_type
	NSString* dType = [description valueForKey:@"device_type"];
	if (dType == nil || ([dType caseInsensitiveCompare:[self deviceType]] != NSOrderedSame))
		return NO;
	
	//passed all checks, hence the description matches
	return YES;
}

- (NSDictionary*) sensorDescription {return nil;}
+ (BOOL) isAvailable {return NO;}

- (id) init {
	self = [super init];
	 if (self) {
         //TODO:, actually [self sensorId] should be used, but that means the settings shoudl also somehow use that, not used the name portion, have to decide how to fix that
		 //register for enable changed notification
		 [[NSNotificationCenter defaultCenter] addObserver:self
												  selector:@selector(enabledChanged:)
													  name:[Settings enabledChangedNotificationNameForSensor:[self name]] object:nil];
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
    return [Sensor sensorIdFromName:self.name andDeviceType:self.deviceType];
}

+ (NSString*) sensorIdFromName:(NSString*)name andDeviceType:(NSString*)deviceType {
    NSString* separator = @"/";
    NSString* escapedSeparator = @"//";
    NSString* escapedName = [name stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    NSString* escapedDeviceType = [deviceType stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    return [NSString stringWithFormat:@"%@%@%@", escapedName, separator, escapedDeviceType];
}

+ (NSString*) sensorNameFromSensorId:(NSString*) sensorId {
    //extract sensor name
    NSMutableString* name = [[NSMutableString alloc] init];
    for (size_t i = 0; i < sensorId.length; i++) {
        char ch = [sensorId characterAtIndex:i];
        if (ch != '/'){
            [name appendFormat:@"%c", ch];
        } else {
            if (i+1 < sensorId.length && [sensorId characterAtIndex:i+1] == '/') {
                //skip, as this is an escaped slash
                i++;
                continue;
            }
            break;
        }
    }
    return name;
}

@end
