//
//  JumpDetector.m
//  sense platform library
//
//  Created by Pim Nijdam on 6/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JumpSensor.h"
#import <CoreMotion/CoreMotion.h>
#import "DataStore.h"
#import "JSON.h"


//Stuff needed for jump detection
typedef struct {double x, y, z;} Vec3d;
typedef enum {REST, TAKE_OFF, FLIGHT, LANDING, LANDING2} State;
const static double alpha = 0.7;

static double inprod(Vec3d inx, Vec3d iny) {
    return inx.x*iny.x + inx.y*iny.y + inx.z*iny.z;
}

static double projectionMagnitude( Vec3d inVec, Vec3d onVec) {
    return inprod(inVec, onVec) / inprod(onVec, onVec);
}

//constants
NSString* const jumpHeightKey = @"height";

@implementation JumpSensor {
    State jumpState;
    double filteredG;
    
    NSTimeInterval takeOffStart, flightStart, landingStart;
}

- (NSString*) name {return kSENSOR_JUMP;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", jumpHeightKey,
							nil];
	//make string, as per spec
	NSString* json = [format JSONRepresentation];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"json", @"data_type",
			json, @"data_structure",
			nil];
}

- (id) init {
    self = [super init];
    if (self) {
        jumpState = REST;
    }
    return self;
}

- (void) pushDeviceMotion: (CMDeviceMotion*) motion {
    //get raw accelerometer values
    const double ax =motion.userAcceleration.x + motion.gravity.x;
    const double ay =motion.userAcceleration.y + motion.gravity.y;
    const double az =motion.userAcceleration.z + motion.gravity.z;
    
    //project onto gravity
    const Vec3d motionVector = {ax, ay, az};
    const Vec3d gravityVector = {motion.gravity.x, motion.gravity.y, motion.gravity.z};
    const double h = projectionMagnitude(motionVector, gravityVector);    
    
    //low-pass filter
    filteredG = alpha * filteredG + (1-alpha) * h;

    //jump detection thresholds
    const double thTakeOff = 1.5;
    const double thFlight = 0.5;
    const double thLanding = 0.6;
    const double thLandingPeak = 1.3;
    const double thRest = 1.2;
    
    //use filter value as input
    const double gg = filteredG;
    
    //state machine for jump detection
    const NSTimeInterval now = motion.timestamp;
    switch (jumpState) {
        case REST:
            if (gg > thTakeOff) {
                takeOffStart = now;
                jumpState = TAKE_OFF;
            }
            
            break;
        case TAKE_OFF:
            if (gg < thFlight) {
                flightStart = now;
                jumpState = FLIGHT;
            }
            break;
        case FLIGHT:
            if (gg > thLanding) {
                landingStart = now;
                jumpState = LANDING;
                [self jumpDetected];
            }
            break;
        case LANDING:
            if (gg > thLandingPeak)
                jumpState = LANDING2;
            break;
        case LANDING2:
            if (gg < thRest)
                jumpState = REST;
            break;
    }
}

- (void) jumpDetected {
    //TODO: some sanity checks like minimal/maximal take off time?
    //calculate some features of the jump
    NSTimeInterval flightTime = landingStart - flightStart;
    //NSTimeInterval takeOffTime = flightStart - takeOffStart;
    //calculate height based on flight time
    const double height = .5 *  9.81 * (flightTime/2) * (flightTime/2);

    //TODO: report jump
    NSLog(@"Jumped %.0f cm", height * 100);
    
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%.3f", height], jumpHeightKey,
									nil];

	double timestamp = [[NSDate date] timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										[newItem JSONRepresentation], @"value",
										[NSString stringWithFormat:@"%.3f",timestamp],@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
}


@end
