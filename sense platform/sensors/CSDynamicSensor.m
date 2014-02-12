/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import "CSDynamicSensor.h"
#import "CSDataStore.h"
#import "CSSensePlatform.h"
#import "Formatting.h"

@implementation CSDynamicSensor {
    NSDictionary* fields;
    NSDictionary* deviceDict;
}
- (NSString*) name {return sensorName;}
- (NSString*) deviceType {return deviceType;}
+ (BOOL) isAvailable {return YES;}
- (NSDictionary*) device {return deviceDict;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
    NSString* dataStructure = @"";
    if ([dataType isEqualToString: kCSDATA_TYPE_JSON]) {
        if (fields != nil) {
            NSError* error = nil;
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:fields options:0 error:&error];
            dataStructure = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            
        }
        return [NSDictionary dictionaryWithObjectsAndKeys:
                [self name], @"name",
       			[self displayName], @"display_name",
                [self deviceType], @"device_type",
                @"", @"pager_type",
                dataType, @"data_type",
                dataStructure, @"data_structure",
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
        deviceDict = [super device];
	}
	return self;
}

- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields device:(NSDictionary*) device {
	self = [super init];
	if (self) {
        sensorName = name;
        displayName = dispName;
        deviceType = devType;
        dataType = datType;
        deviceDict = device;
	}
	return self;
}


- (void) commitValue:(id)value withTimestamp:(NSTimeInterval)timestamp {
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										value, @"value",
										CSroundedNumber(timestamp, 3),@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//NSLog(@"%@ %@ sensor (id=%@)", enable ? @"Enabling":@"Disabling", sensorName, self.sensorId);
	isEnabled = enable;
}

- (void) dealloc {
    //NSLog(@"Deallocating %@", sensorName);
	self.isEnabled = NO;
}

@end
