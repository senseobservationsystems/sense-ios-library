//
//  Sender.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSON.h"

@interface Sender : NSObject {
	@private
	NSString* sessionCookie;
	NSDictionary* urls;
	NSString* username;
	NSString* passwordHash;
}

@property (strong) NSDictionary* urls;
@property (strong) NSString* sessionCookie;

- (id) init;
- (void) setUser:(NSString*)user andPassword:(NSString*) password;
- (BOOL) isLoggedIn;
- (BOOL) registerUser:(NSString*) username withPassword:(NSString*) password error:(NSString**)error;
- (BOOL) login;
- (BOOL) logout;
- (NSDictionary*) listSensors;
- (NSDictionary*) listSensorsForDevice:(NSDictionary*)device;
- (NSDictionary*) createSensorWithDescription:(NSDictionary*) description;
- (BOOL) connectSensor:(NSString*)sensorId ToDevice:(NSDictionary*) device;
- (BOOL) uploadData:(NSArray*) data forSensorId:(NSString*)sensorId;
- (BOOL) shareSensor: (NSString*)sensorId WithUser:(NSString*)user;
@end
