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

#import "CSJumpSensor.h"
#import <CoreMotion/CoreMotion.h>
#import "CSDataStore.h"

#define DEGREES_PER_RADIAN (180.0 / M_PI)


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
static NSString* const jumpHeightKey = @"height";
static NSString* const jumpTakeOffHeadingKey = @"take off heading";
static NSString* const jumpLandingHeadingKey = @"landing heading";

@implementation CSJumpSensor {
    State jumpState;
    double filteredG;
    
    NSTimeInterval takeOffStart, flightStart, landingStart;
    double takeOffHeading, landingHeading;
}

- (NSString*) name {return kCSSENSOR_JUMP;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", jumpHeightKey,
							@"string", jumpTakeOffHeadingKey,
							@"string", jumpLandingHeadingKey,
							nil];
	//make string, as per spec
    NSError* error;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
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

- (void) pushDeviceMotion: (CMDeviceMotion*) motion andManager:(CMMotionManager*) motionManager {
    //get raw accelerometer values
    const double ax =motion.userAcceleration.x + motion.gravity.x;
    const double ay =motion.userAcceleration.y + motion.gravity.y;
    const double az =motion.userAcceleration.z + motion.gravity.z;
    
    //get time
    const NSTimeInterval now = motion.timestamp;
    
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
    const NSTimeInterval thJumpContinuation = 0.7;
    const NSTimeInterval thJumpContinuationMin = 0.05;
    const NSTimeInterval jumpTimeout = 1;
    
    //use filter value as input
    const double gg = filteredG;
    
    //simple reset rule
    double timeSinceTakeOff = now - takeOffStart;
    if (jumpState != REST && timeSinceTakeOff > jumpTimeout) {
        jumpState = REST;
    }
    
    //state machine for jump detection
    switch (jumpState) {
        case REST: {
            NSTimeInterval dt = now - landingStart;
            if (gg > thTakeOff) {
                takeOffStart = now;
                //get yaw from motionManager, as only that one seems to use the specified reference frame, and not the motion in the handler
                takeOffHeading = motionManager.deviceMotion.attitude.yaw;
                jumpState = TAKE_OFF;
            } else if (gg < thFlight && dt <= thJumpContinuation && dt >= thJumpContinuationMin) {
                takeOffStart = now;
                //get yaw from motionManager, as only that one seems to use the specified reference frame, and not the motion in the handler
                takeOffHeading = motionManager.deviceMotion.attitude.yaw;
                jumpState = TAKE_OFF;
            }
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
                //get yaw from motionManager, as only that one seems to use the specified reference frame, and not the motion in the handler
                landingHeading = motionManager.deviceMotion.attitude.yaw;
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
    //TODO: some sanity checks like minimum/maximum take off time?
    //calculate some features of the jump
    NSTimeInterval flightTime = landingStart - flightStart;
    //NSTimeInterval takeOffTime = flightStart - takeOffStart;
    //calculate height based on flight time
    const double height = .5 *  9.81 * (flightTime/2) * (flightTime/2);
    
    //discard really low jumps
    if (height < 0.01) return;
    
    const double landingDegrees = [self normDegrees:(-landingHeading * DEGREES_PER_RADIAN + 180) toRange:360];
    const double takeOffDegrees = [self normDegrees:(-takeOffHeading * DEGREES_PER_RADIAN + 180) toRange:360];
    
    
    NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%.3f", height], jumpHeightKey,
									[NSString stringWithFormat:@"%.0f", takeOffDegrees], jumpTakeOffHeadingKey,
									[NSString stringWithFormat:@"%.0f", landingDegrees], jumpLandingHeadingKey,
									nil];

	double timestamp = [[NSDate date] timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										[NSString stringWithFormat:@"%.3f",timestamp],@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
}

- (double) normDegrees:(double) degreesIn toRange:(double)range {
    while (degreesIn < 0)
        degreesIn += range;
    while (degreesIn >= range)
        degreesIn -= range;
    return degreesIn;
}


@end
