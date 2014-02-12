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

+ (NSString*) sensorIdFromName:(NSString*)name andDeviceType:(NSString*)description andDevice:(NSDictionary *)device {
    NSString* separator = @"/";
    NSString* escapedSeparator = @"//";
    NSString* escapedName = [name stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    NSString* escapedDescription = [description stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
    
    if (device != nil) {
        NSString* deviceType = [device valueForKey:@"type"];
        NSString* deviceUUID = [device valueForKey:@"uuid"];
        NSString* escapedDeviceType = [deviceType stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
        NSString* escapedDeviceUUID = [deviceUUID stringByReplacingOccurrencesOfString:separator withString:escapedSeparator];
        return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", escapedName, separator, escapedDescription, separator, escapedDeviceType, separator, escapedDeviceUUID];
    } else {
        return [NSString stringWithFormat:@"%@%@%@", escapedName, separator, escapedDescription];
    }
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
