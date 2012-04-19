//
//  Sensor.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface Sensor : NSObject {
	BOOL isEnabled;
	//delegate
	id dataStore;
}

@property (assign) BOOL isEnabled;
@property (strong) id dataStore;
@property (readonly) NSString* sensorId;


- (BOOL) matchesDescription:(NSDictionary*) description;

//common methods
- (void) enabledChanged: (id) notification;

//implemented by device if it needs a 'run' method
- (void) dealloc;

//overridden by subclass
- (NSString*) name;
- (NSString*) displayName;
- (NSString*) deviceType;
- (NSDictionary*) sensorDescription;
+ (BOOL) isAvailable;
- (NSString*) sensorId;
@end
