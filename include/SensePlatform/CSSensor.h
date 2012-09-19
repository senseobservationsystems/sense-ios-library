//
//  Sensor.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "CSSensorIds.h"

/** The base object for each sensor.
 */
@interface CSSensor : NSObject {
	BOOL isEnabled;
	//delegate
	id dataStore;
}

@property (assign) BOOL isEnabled;
///The data store the sensor commits it's obtained values to
@property (strong) id dataStore;
@property (readonly) NSString* sensorId;

///Method to check wether the sensor matches the given description of the sensor
- (BOOL) matchesDescription:(NSDictionary*) description;

///Method that will be invoked when the sensor is enabled/disabled
- (void) enabledChanged: (id) notification;

//overridden by subclass
///Returns name of the sensor
- (NSString*) name;
///Returns the display name of the sensor
- (NSString*) displayName;
///Returns the device type of the sensor
- (NSString*) deviceType;
///Returns the description of the sensor
- (NSDictionary*) sensorDescription;
///Returns wether this sensor is available
+ (BOOL) isAvailable;
///Returns the sensor id of the sensor, a unique name that is used by the library to uniquely identify the sensor. This is NOT the id of the sensor in Common Sense
- (NSString*) sensorId;

///Create sensor id
+ (NSString*) sensorIdFromName:(NSString*)name andDeviceType:(NSString*)deviceType;
///Extract sensor name from the sensor id
+ (NSString*) sensorNameFromSensorId:(NSString*) sensorId;
@end
