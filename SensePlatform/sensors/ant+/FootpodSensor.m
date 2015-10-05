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
#if 0

#import "FootpodSensor.h"
#import "DataStore.h"
#import "Settings.h"
#import "JSON.h"

static const NSString* cadenceKey = @"cadence";
static const NSString* speedKey = @"speed";


@implementation FootpodSensor {
    WFSensorConnection* connection;
}

+ (NSString*) name {return @"footpod";}
+ (NSString*) displayName {return @"footpod";}
+ (NSString*) deviceType {return [self name]; } //TODO: use footpod id...???
+ (BOOL) isAvailable {return YES;}


+ (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self displayName], @"display_name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"float", @"data_type",
			nil];
}

- (id) initWithConnection:(WFSensorConnection *)conn {
	self = [super init];
	if (self) {
		connection = conn;
        connection.delegate = self;
		//register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[Settings settingChangedNotificationNameForType:@"footpod"] object:nil];

	}
	return self;
}



- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ footpod sensor (id=%@)", enable ? @"Enablig":@"Disabling", self.sensorId);
    isEnabled = enable;
}

- (void) checkData {
    NSLog(@"sensor %@ data", connection.hasData ? @"has" : @"has no");
    if (connection.hasData == NO)
        return;
    
    WFFootpodConnection* fpConnection = (WFFootpodConnection*) connection;
    float cadence = fpConnection.getFootpodData.cadence;
    float speed = fpConnection.getFootpodData.instantaneousSpeed;
    double timestamp = [[NSDate date] timeIntervalSince1970];
    
    NSDictionary* newItem = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%.1f", cadence], cadenceKey,
									[NSString stringWithFormat:@"%.2f", speed], speedKey,
									nil];
  	
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										[NSString stringWithFormat:@"%.3f", timestamp], @"date",
										nil];
    [dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}


- (void) settingChanged: (NSNotification*) notification {
	@try {
		Setting* setting = notification.object;
		NSLog(@"footpod: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:@"interval"]) {
		}
	}
	@catch (NSException * e) {
		NSLog(@"footpod: Exception thrown while changing setting: %@", e);
	}
	
}

- (void) dealloc {
	NSLog(@"Deallocating footpod sensor");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.isEnabled = NO;
}

- (void)connection:(WFSensorConnection*)connectionInfo stateChanged:(WFSensorConnectionStatus_t)connState
{
    NSLog(@"footpod: sensor state changed: connState = %d (idle=%d)",connState,WF_SENSOR_CONNECTION_STATUS_IDLE);
}

@end

#endif
