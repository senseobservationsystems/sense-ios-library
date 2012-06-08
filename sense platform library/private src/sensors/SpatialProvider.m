//
//  SpatialProvider.m
//  senseApp
//
//  Created by Pim Nijdam on 3/25/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "SpatialProvider.h"
#import "JSON.h"
#import "SensorStore.h"
#import "NSNotificationCenter+MainThread.h"
#import "Settings.h"
#import "MotionEnergySensor.h"
#import "MotionFeaturesSensor.h"
#import "JumpSensor.h"

static const double G = 9.81;
static const double radianInDegrees = 180 / M_PI;

@implementation SpatialProvider {
    CLLocationManager* locationManager;
	CMMotionManager* motionManager;
	
	CompassSensor* compassSensor;
	AccelerometerSensor* accelerometerSensor;
	OrientationSensor* orientationSensor;
	AccelerationSensor* accelerationSensor;
	RotationSensor* rotationSensor;
    MotionEnergySensor* motionEnergySensor;
    MotionFeaturesSensor* motionFeaturesSensor;
	
	NSOperationQueue* operations;
  	NSOperationQueue* pollQueue;
    NSCondition* headingAvailable;
    BOOL updatingHeading;
    
    NSTimeInterval interval;
    NSInteger nrSamples;
    double frequency;
    NSTimer* pollTimer;
    
    BOOL jumpDetection;
    JumpSensor* jumpDetector;
}

- (id) initWithCompass:(CompassSensor*)compass orientation:(OrientationSensor*)orientation accelerometer:(AccelerometerSensor*)accelerometer acceleration:(AccelerationSensor*)acceleration rotation:(RotationSensor*)rotation jumpSensor:(JumpSensor*) jumpSensor{
	self = [super init];
	if (self) {
		NSLog(@"spatial provider init");
        jumpDetection = YES;
        jumpDetector = jumpSensor;
		compassSensor = compass; orientationSensor = orientation; accelerometerSensor = accelerometer; accelerationSensor = acceleration; rotationSensor = rotation;
        motionEnergySensor = [[MotionEnergySensor alloc] init];
        motionFeaturesSensor = [[MotionFeaturesSensor alloc] init];
		motionManager = [[CMMotionManager alloc] init];
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
        
		//Set settings
		@try {
            interval = [[[Settings sharedSettings] getSettingType:kSettingTypeSpatial setting:kSpatialSettingInterval] doubleValue];
   			frequency = [[[Settings sharedSettings] getSettingType:kSettingTypeSpatial setting:kSpatialSettingFrequency] doubleValue];
  			nrSamples = [[[Settings sharedSettings] getSettingType:kSettingTypeSpatial setting:kSpatialSettingNrSamples] intValue];
            NSLog(@"interval %.0f, freq %.0f, nrSamples %i", interval, frequency, nrSamples);
		}
		@catch (NSException * e) {
			NSLog(@"spatial provider: Exception thrown while setting: %@", e);
		}
		//TODO: properly manage this setting
		locationManager.headingFilter = 10;
		
		//operations queue
		operations = [[NSOperationQueue alloc] init];
   		pollQueue = [[NSOperationQueue alloc] init];
        
        headingAvailable = [[NSCondition alloc] init];
        updatingHeading = NO;
		
		//enable
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accelerometerEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:kSENSOR_ACCELEROMETER] object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rotationEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:kSENSOR_ROTATION] object:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(orientationEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:kSENSOR_ORIENTATION] object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(jumpEnabledChanged:)
													 name:[Settings enabledChangedNotificationNameForSensor:kSENSOR_JUMP] object:nil];
		
		//register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[Settings settingChangedNotificationNameForType:kSettingTypeSpatial] object:nil];
	}
    
	return self;
}

- (void) jumpEnabledChanged: (id) notification {
    //UGLY hack to use jump detection
	bool enable = [[notification object] boolValue];
    jumpDetection = enable;
    
    [motionManager stopDeviceMotionUpdates];
    [NSTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(schedulePoll) userInfo:nil repeats:NO];
}

- (void) accelerometerEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue];
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerationSensor != nil && accelerationSensor.isEnabled) || (rotationSensor != nil && rotationSensor.isEnabled) || (orientationSensor != nil && orientationSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) rotationEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue] && (rotationSensor != nil);
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerometerSensor != nil && accelerometerSensor.isEnabled) || (orientationSensor != nil && orientationSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) orientationEnabledChanged:(id)notification {
	bool enable = [[notification object] boolValue] && (orientationSensor != nil);
    //check to see wether the timer needs to be enabled/disabled
    bool otherIsEnabled = (accelerationSensor != nil && accelerationSensor.isEnabled) || (rotationSensor != nil && rotationSensor.isEnabled) || (accelerometerSensor != nil && accelerometerSensor.isEnabled);
    if (enable || otherIsEnabled) {
        //make sure timer is scheduled
        if (NO == [pollTimer isValid]) {
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:YES];
        }
    }
	if (enable == NO && otherIsEnabled == NO) {
        //stop the timer
        [pollTimer invalidate];
	}
}

- (void) schedulePoll {
    @try {
        //make a poll operation
        NSInvocationOperation* pollOp = [[NSInvocationOperation alloc]
                                         initWithTarget:self selector:@selector(poll) object:nil];
        [pollQueue addOperation:pollOp];
    }
    @catch (NSException * e) {
        NSLog(@"Catched exception while scheduling poll. Exception: %@", e);
    }
}

- (void) poll {
    NSLog(@"^^^ Spatial provider poll invoked. ^^^");
    
    
    //prepare arrays for data
    __block NSMutableArray* deviceMotionArray = [[NSMutableArray alloc] initWithCapacity:nrSamples];
    //__block CMAttitude* attitude;
    __block NSMutableArray* timestampArray = [[NSMutableArray alloc] initWithCapacity:nrSamples];
    __block int sample = 0;
    
    NSCondition* dataCollectedCondition = [NSCondition new];
    
    __block NSInteger counter = 0;
    __block NSInteger discarded = 0;
    
    
    CMDeviceMotionHandler deviceMotionHandler = ^(CMDeviceMotion* deviceMotion, NSError* error) {
        if (jumpDetection) {
            [jumpDetector pushDeviceMotion:deviceMotion];
            return;
        }
            
        if (counter > 0) {
            //Oh no, we're not processing fast enough. This means problems...
            discarded++;
            NSLog(@"Processing too slow, skipping point, this corrupts sensor input temporarily!");
            return;
        }
        counter++;
        //Note: deviceMotion.timestamp is relative to some reference, not unix time
        [timestampArray addObject:[NSDate date]]; //ai ai, object creation can slow down stuff..
        [deviceMotionArray addObject:deviceMotion];
        
        //if we've sampled enough
        if (++sample >= nrSamples) {
            [motionManager stopDeviceMotionUpdates];
            //signal that we're done collecting
            [dataCollectedCondition broadcast];
        }
        counter--;
        
    };
    motionManager.deviceMotionUpdateInterval = 1./frequency;
    [dataCollectedCondition lock];
    //[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue:operations withHandler:deviceMotionHandler];
    NSLog(@"Start sampling motion with %.0f Hz", frequency);
    [motionManager startDeviceMotionUpdatesToQueue:operations withHandler:deviceMotionHandler];
    // Aquire heading, this may take some time ( 1 second)
    //float heading = -1;
    /*
     if (hasOrientation) {
     if (!updatingHeading) {
     //wait for heading to be available 
     [headingAvailable lock];
     [locationManager startUpdatingHeading];
     updatingHeading = YES;
     [headingAvailable wait];
     [headingAvailable unlock];
     }
     heading = locationManager.heading.magneticHeading;
     }
     */
    //wait until all data collected
    [dataCollectedCondition wait];
    [dataCollectedCondition unlock];
    
    //post device motion //TODO: is there a better way to efficiently share data?
    NSDictionary* data = [NSDictionary dictionaryWithObject:deviceMotionArray forKey:@"data"];
    NSNotification* notification = [NSNotification notificationWithName:kMotionData object:self userInfo:data];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    
    //either send all samples, or just the first
    BOOL rawSamples = NO, stats = YES;
    
    if (rawSamples)
        [self commitRawSamples:deviceMotionArray withTimestamps:timestampArray];
    else {
        NSRange range = NSMakeRange(0, 1);
        [self commitRawSamples:[deviceMotionArray subarrayWithRange:range] withTimestamps:[timestampArray subarrayWithRange:range]];
    }
    
    if (stats) {
        [self commitMotionFeaturesForSamples:deviceMotionArray withTimestamp:[timestampArray objectAtIndex:0]];
    }
}

- (void) commitMotionFeaturesForSamples:(NSArray*)deviceMotionArray withTimestamp:(NSDate*) timestampDate {
    //commit average, stddev and kurtosis
    double magnitudeSum=0, magnitudeSqSum=0;
    double totalRotSum=0, totalRotSqSum=0;
    for (CMDeviceMotion* deviceMotion in deviceMotionArray) {
        CMAcceleration a = deviceMotion.userAcceleration;
        double magnitude = sqrt(a.x * G * a.x * G + a.y * G *a.y * G + a.z * G *a.z * G);
        
        magnitudeSum += magnitude;
        magnitudeSqSum += magnitude * magnitude;
        
        CMRotationRate r = deviceMotion.rotationRate;
        double totalRot = sqrt(r.x * r.x + r.y * r.y + r.z * r.z);
        
        totalRotSum += totalRot;
        totalRotSqSum += totalRot * totalRot;
    }
    //set magnitude related features
    double magnitudeAvg = magnitudeSum / [deviceMotionArray count];
    double meanSquares = magnitudeSqSum / [deviceMotionArray count];
    double magnitudeStddev = meanSquares - magnitudeAvg*magnitudeAvg;
    
    //rotation related features
    double totalRotAvg = totalRotSum / [deviceMotionArray count];
    double totalRotMeanSquares = totalRotSqSum / [deviceMotionArray count];
    double totalRotStddev = totalRotMeanSquares - totalRotAvg*totalRotAvg;

    //commit values
    NSTimeInterval timestamp = [timestampDate timeIntervalSince1970];
    
    [[SensorStore sharedSensorStore] addSensor:motionEnergySensor];
    [[SensorStore sharedSensorStore] addSensor:motionFeaturesSensor];
    
    //commit motion energy
    NSString* value = [NSString stringWithFormat:@"%.3f", magnitudeStddev];
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        value, @"value",
                                        [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                        nil];
    [motionEnergySensor.dataStore commitFormattedData:valueTimestampPair forSensorId:motionEnergySensor.sensorId];
    
    value = [[NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%.3f", magnitudeAvg], accelerationAvg,
							[NSString stringWithFormat:@"%.3f", magnitudeStddev], accelerationStddev,
							@"", accelerationKurtosis,
							[NSString stringWithFormat:@"%.3f", totalRotAvg], rotationAvg,
							[NSString stringWithFormat:@"%.3f", totalRotStddev], rotationStddev,
							@"", rotationKurtosis,
							nil] JSONRepresentation];
    
    valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        value, @"value",
                                        [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                        nil];
    [motionFeaturesSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:motionFeaturesSensor.sensorId];
}

- (void) commitRawSamples:(NSArray*) deviceMotionArray withTimestamps: (NSArray*) timestampArray {
    BOOL hasOrientation = orientationSensor != nil && orientationSensor.isEnabled;
    BOOL hasAccelerometer = accelerometerSensor != nil && accelerometerSensor.isEnabled;
    BOOL hasAcceleration = accelerationSensor != nil && accelerationSensor.isEnabled;
    BOOL hasRotation = rotationSensor != nil && rotationSensor.isEnabled;
    float heading = -1;
    
    for (size_t i = 0; i < [deviceMotionArray count]; i++) {
        NSTimeInterval timestamp = [[timestampArray objectAtIndex:i] timeIntervalSince1970];
        CMDeviceMotion* motion = [deviceMotionArray objectAtIndex:i];
        
        //Commit samples for the sensors
        if (hasOrientation) {
            CMAttitude* attitude = motion.attitude;
            NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSString stringWithFormat:@"%.3f", attitude.pitch * radianInDegrees], attitudePitchKey,
                                            [NSString stringWithFormat:@"%.3f", attitude.roll * radianInDegrees], attitudeRollKey,
                                            [NSString stringWithFormat:@"%.0f", heading], attitudeYawKey,
                                            nil];
            
            NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [newItem JSONRepresentation], @"value",
                                                [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                nil];
            [orientationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:orientationSensor.sensorId];
            
        }
        
        
        if (hasAccelerometer) {
            double x = motion.gravity.x + motion.userAcceleration.x;
            double y = motion.gravity.y + motion.userAcceleration.y;
            double z = motion.gravity.z + motion.userAcceleration.z;
            NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSString stringWithFormat:@"%.3f", x * G], accelerationXKey,
                                            [NSString stringWithFormat:@"%.3f", y * G], accelerationYKey,
                                            [NSString stringWithFormat:@"%.3f", z * G], accelerationZKey,
                                            nil];
            
            NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [newItem JSONRepresentation], @"value",
                                                [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                nil];
            
            [accelerometerSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerometerSensor.sensorId];
            
            
        }
        
        if (hasAcceleration) {
            double x = motion.userAcceleration.x * G;
            double y = motion.userAcceleration.y * G;
            double z = motion.userAcceleration.z * G;
            NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSString stringWithFormat:@"%.3f", x], accelerationXKey,
                                            [NSString stringWithFormat:@"%.3f", y], accelerationYKey,
                                            [NSString stringWithFormat:@"%.3f", z], accelerationZKey,
                                            nil];
            
            NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [newItem JSONRepresentation], @"value",
                                                [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                nil];
            [accelerationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerationSensor.sensorId];
        }
        
        if (hasRotation) {
            double pitch = motion.rotationRate.x * radianInDegrees;
            double roll = motion.rotationRate.y * radianInDegrees;
            double yaw = motion.rotationRate.z * radianInDegrees;
            NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSString stringWithFormat:@"%.3f", pitch], attitudePitchKey,
                                            [NSString stringWithFormat:@"%.3f", roll], attitudeRollKey,
                                            [NSString stringWithFormat:@"%.3f", yaw], attitudeYawKey,
                                            nil];
            
            NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                                [newItem JSONRepresentation], @"value",
                                                [NSString stringWithFormat:@"%.3f", timestamp],@"date",
                                                nil];
            [rotationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:rotationSensor.sensorId];
        }
    }
}
    
    
    
- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
    return NO;
}


//implement delegate
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    //wake up threads waiting for a heading
    [headingAvailable broadcast];
    //if compass isn't enabled, it was just a one time need for a heading, so stop updating
    if (compassSensor.isEnabled == NO && interval > 1) {
        [locationManager stopUpdatingHeading];
        updatingHeading = false;
        return;
    }
}

- (void) settingChanged: (NSNotification*) notification {
    @try {
        Setting* setting = notification.object;
        NSLog(@"Spatial: setting %@ changed to %@.", setting.name, setting.value);
        if ([setting.name isEqualToString:kSpatialSettingInterval]) {
            interval = [setting.value doubleValue];
            [pollTimer invalidate];;
            pollTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(schedulePoll) userInfo:nil repeats:!jumpDetection];
        } else if ([setting.name isEqualToString:kSpatialSettingFrequency]) {
            frequency = [setting.value doubleValue];
        } else if ([setting.name isEqualToString:kSpatialSettingNrSamples]) {
            nrSamples = [setting.value intValue];
        }
    }
    @catch (NSException * e) {
        NSLog(@"spatial provider: Exception thrown while changing setting: %@", e);
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pollTimer invalidate];
    
    [operations cancelAllOperations];
}

@end
