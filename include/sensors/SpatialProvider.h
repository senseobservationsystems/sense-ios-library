//
//  SpatialProvider.h
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "CompassSensor.h"
#import "OrientationSensor.h"
#import "AccelerometerSensor.h"
#import "AccelerationSensor.h"
#import "RotationSensor.h"
#import <pthread.h>

@interface SpatialProvider : NSObject <CLLocationManagerDelegate>{
	CLLocationManager* locationManager;
	CMMotionManager* motionManager;
	
	CompassSensor* compassSensor;
	AccelerometerSensor* accelerometerSensor;
	OrientationSensor* orientationSensor;
	AccelerationSensor* accelerationSensor;
	RotationSensor* rotationSensor;
	
	NSOperationQueue* operations;
  	NSOperationQueue* pollQueue;
    NSCondition* headingAvailable;
    BOOL updatingHeading;
    
    BOOL continuously;
    NSTimeInterval interval;
    double frequency, sampleTime;
    NSTimer* pollTimer;
}

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation;
- (void) accelerometerEnabledChanged: (id) notification;
- (void) rotationEnabledChanged: (id) notification;
- (void) orientationEnabledChanged: (id) notification;
- (void) settingChanged: (NSNotification*) notification;
- (void) schedulePoll;
- (void) poll;
@end
