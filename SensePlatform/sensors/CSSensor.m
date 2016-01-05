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

#import "CSSensor.h"
#import "CSSettings.h"
#import "CSSensorStore.h"
#import "CSSensorConstants.h"
#import "Formatting.h"

@import DSESwift;


@implementation CSSensor
@synthesize dataStore;
@synthesize isEnabled;

//constants
- (NSString*) name {return @"";}
- (NSString*) displayName {return [self name];}
- (NSString*) deviceType {return @"";}
- (NSDictionary*) device {return [CSSensorStore device];}

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
													  name:[CSSettings enabledChangedNotificationNameForSensor:[self name]] object:nil];
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
    return [CSSensor sensorIdFromName:self.name andDeviceType:self.deviceType andDevice:self.device];
}

- (void) commitDataPointWithValue:(id)value andTime: (NSDate*) time{
    // Broadcast the data
    NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                value, @"value",
                                                CSroundedNumber([time timeIntervalSince1970], 3),@"date",
                                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSNewSensorDataNotification object:self.name userInfo:data];
    
    //Insert data to dse
    NSError* error = nil;
    DataStorageEngine* dse = [DataStorageEngine getInstance];
    Sensor* sensor = [dse getSensor:CSSorceName_iOS sensorName:self.name error:&error];
    if(error){
        NSLog(@"error while calling getSensor. Error:%@:", error);
    }
    error = nil;
    [sensor insertOrUpdateDataPointWithValue:value time:time error:&error];
    if(error){
        NSLog(@"error while calling insertOrUpdate. Error:%@:", error);
    }
}

+ (NSString*) sensorIdFromName:(NSString*)name andDeviceType:(NSString*)description andDevice:(NSDictionary *)device {
    NSString* separator = @"/";
    NSString* escapedSeparator = @"//";
    NSString* escapedName = [name stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    NSString* escapedDescription = [description stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    NSString* deviceType = @"";
    NSString* deviceUUID = @"";
    if (device != nil) {
        deviceType = [device valueForKey:@"type"];
        deviceUUID = [device valueForKey:@"uuid"];
    }

    NSString* escapedDeviceType = [deviceType stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    NSString* escapedDeviceUUID = [deviceUUID stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", escapedName, separator, escapedDescription, separator, escapedDeviceType, separator, escapedDeviceUUID];
}

+ (NSString*) sensorNameFromSensorId:(NSString*) sensorId {
    return [[CSSensor componentsFromSensorId:sensorId] objectAtIndex:0];
}
+ (NSString*) sensorDescriptionFromSensorId:(NSString*) sensorId {
    return [[CSSensor componentsFromSensorId:sensorId] objectAtIndex:1];
}
+ (NSString*) sensorDeviceTypeFromSensorId:(NSString*) sensorId {
    return [[CSSensor componentsFromSensorId:sensorId] objectAtIndex:2];
}
+ (NSString*) sensorDeviceUUIDFromSensorId:(NSString*) sensorId {
    return [[CSSensor componentsFromSensorId:sensorId] objectAtIndex:3];
}

+ (NSArray*) componentsFromSensorId:(NSString*) sensorId {
    
    NSArray* tmp = [[sensorId stringByReplacingOccurrencesOfString:@"//" withString:@"/"] componentsSeparatedByString:@"/"];

    //TODO:with empty values something might go wrong. E.g. name//device/device. The description is empty. This will put the wrong fields...
    
    NSMutableArray* components = [tmp mutableCopy];
    //This should've returned 4 entries: name/description/deviceType/uuid, if not just fill in the missing components as empty
    while (components.count < 4) {
        [components addObject:@""];
    }
    return components;
}

@end
