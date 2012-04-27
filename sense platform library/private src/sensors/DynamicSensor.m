//
//  DynamicSensor.m
//  fiqs
//
//  Created by Pim Nijdam on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DynamicSensor.h"
#import "DataStore.h"
#import "SensePlatform.h"
#import "JSON.h"

@implementation DynamicSensor {
    NSDictionary* fields;
}
- (NSString*) name {return sensorName;}
- (NSString*) deviceType {return deviceType;}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
    NSString* dataStructure = @"";
    if ([dataType isEqualToString: kSENSEPLATFORM_DATA_TYPE_JSON]) {
        if (fields != nil)
            dataStructure = [fields JSONRepresentation];
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [self name], @"name",
       			[self displayName], @"display_name",
                [self deviceType], @"device_type",
                @"", @"pager_type",
                dataType, @"data_type",
                @"", @"data_structure",
                nil];
    }
    
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
   			[self displayName], @"display_name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			dataType, @"data_type",
			nil];
}

- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields {
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

- (void) dealloc {
    NSLog(@"Deallocating %@", sensorName);
	self.isEnabled = NO;
}

@end
