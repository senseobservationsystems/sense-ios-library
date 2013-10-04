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

#import "CSSpatialProvider.h"
#import "CSSensorStore.h"
#import "NSNotificationCenter+MainThread.h"
#import "CSSettings.h"
#import "CSMotionEnergySensor.h"
#import "CSMotionFeaturesSensor.h"
#import "CSJumpSensor.h"
#import <pthread.h>
#import "Formatting.h"
#import "CSSensePlatform.h"

static const double G = 9.81;
static const double radianInDegrees = 180.0 / M_PI;

@implementation CSSpatialProvider {
	CMMotionManager* motionManager;
	
	CSCompassSensor* compassSensor;
	CSAccelerometerSensor* accelerometerSensor;
	CSOrientationSensor* orientationSensor;
	CSAccelerationSensor* accelerationSensor;
	CSRotationSensor* rotationSensor;
    CSMotionEnergySensor* motionEnergySensor;
    CSMotionFeaturesSensor* motionFeaturesSensor;
	
	NSOperationQueue* operations;
    dispatch_queue_t pollQueueGCD;
    dispatch_queue_t pollTimerQueueGCD;
    dispatch_source_t pollTimerGCD;
    NSObject* pollTimerLock;
    
    
    NSTimeInterval interval;
    NSInteger nrSamples;
    double frequency;
    bool continuous;
    NSTimeInterval timestampOffset;
    bool isSampling;
    
    CSJumpSensor* jumpDetector;
    
    int enableCounter;
    bool orientationSensorEnabled;
    bool jumpSensorEnabled;
    bool accelerationSensorEnabled;
    bool accelerometerSensorEnabled;
    bool gyroSensorEnabled;
    bool compassSensorEnabled;
}

- (id) initWithCompass:(CSCompassSensor*)compass orientation:(CSOrientationSensor*)orientation accelerometer:(CSAccelerometerSensor*)accelerometer acceleration:(CSAccelerationSensor*)acceleration rotation:(CSRotationSensor*)rotation jumpSensor:(CSJumpSensor*) jumpSensor{
	self = [super init];
	if (self) {
		NSLog(@"spatial provider init");
        jumpDetector = jumpSensor;
		compassSensor = compass; orientationSensor = orientation; accelerometerSensor = accelerometer; accelerationSensor = acceleration; rotationSensor = rotation;
        motionEnergySensor = [[CSMotionEnergySensor alloc] init];
        motionFeaturesSensor = [[CSMotionFeaturesSensor alloc] init];
        
        // motion manager used time since boot, calculate offset
        NSTimeInterval uptime = [NSProcessInfo processInfo].systemUptime;
        NSTimeInterval nowTimeIntervalSince1970 = [[NSDate date] timeIntervalSince1970];
        timestampOffset = nowTimeIntervalSince1970 - uptime;
        
		motionManager = [[CMMotionManager alloc] init];
        
		//Set settings
		@try {
            interval = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval] doubleValue];
   			frequency = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingFrequency] doubleValue];
  			nrSamples = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingNrSamples] intValue];
            NSLog(@"interval %.0f, freq %.0f, nrSamples %i", interval, frequency, nrSamples);
		}
		@catch (NSException * e) {
			NSLog(@"spatial provider: Exception thrown while setting: %@", e);
		}
		
		//operations queue
		operations = [[NSOperationQueue alloc] init];
        
        pollQueueGCD = dispatch_queue_create("com.sense.sense_platform.pollQueue", NULL);
        pollTimerQueueGCD = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        pollTimerLock = [[NSObject alloc] init];

		//enable
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(accelerometerEnabledChanged:)
													 name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_ACCELEROMETER] object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(rotationEnabledChanged:)
													 name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_ROTATION] object:nil];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(orientationEnabledChanged:)
													 name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_ORIENTATION] object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(jumpEnabledChanged:)
													 name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_JUMP] object:nil];
		
		//register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeSpatial] object:nil];
	}
    
	return self;
}

- (void) jumpEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue];
    if (enable != jumpSensorEnabled) {
        if (enable)
            [self incEnable];
        else
            [self decEnable];
    }
    jumpSensorEnabled = enable;
}

- (void) accelerometerEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue];
    if (enable != accelerometerSensorEnabled) {
        if (enable)
            [self incEnable];
        else
            [self decEnable];
    }
    accelerometerSensorEnabled = enable;
}

- (void) rotationEnabledChanged: (id) notification {
	bool enable = [[notification object] boolValue] && (rotationSensor != nil);
    if (enable != gyroSensorEnabled) {
        if (enable)
            [self incEnable];
        else
            [self decEnable];
    }
    gyroSensorEnabled = enable;
}

- (void) orientationEnabledChanged:(id)notification {
	bool enable = [[notification object] boolValue] && (orientationSensor != nil);
    if (enable != orientationSensorEnabled) {
        if (enable)
            [self incEnable];
        else
            [self decEnable];
    }
    orientationSensorEnabled = enable;
}


- (void) schedulePoll {
        dispatch_async(pollQueueGCD, ^{
            @autoreleasepool {

            if (!isSampling) {
                isSampling = YES;
                @try {
                    [self poll];
                }
                @catch (NSException *exception) {
                    NSLog(@"Exception in polling motion sensors: %@\n%@", exception, [NSThread callStackSymbols]);
                }
                isSampling = NO;

                if (continuous) {
                    [self schedulePoll];
                }
            }
            }
        });

    /* DEBUG*/
    //dispatch_async_f(pollQueueGCD, (__bridge void *)(self), someScheduleFunction);
}

void someScheduleFunction(void* context) {
    @autoreleasepool {

    CSSpatialProvider* self = (__bridge CSSpatialProvider*) context;
    if (!self->isSampling) {
        self->isSampling = YES;
        @try {
            [self poll];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception in polling motion sensors: %@\n%@", exception, [NSThread callStackSymbols]);
        }
        self->isSampling = NO;
        
        if (self->continuous) {
            [self schedulePoll];
        }
    }
    }
}


- (void) poll {
    //prepare array for data
    NSMutableArray* deviceMotionArray = [[NSMutableArray alloc] initWithCapacity:nrSamples];
    __block int sample = 0;

    NSCondition* dataCollectedCondition = [NSCondition new];

    __block NSInteger counter = 0;

    CMDeviceMotionHandler deviceMotionHandler = ^(CMDeviceMotion* deviceMotion, NSError* error) {
        if (deviceMotion == nil)
            return;
        if (jumpSensorEnabled) {
            [jumpDetector pushDeviceMotion:deviceMotion andManager:motionManager];
            return;
        }

        /*
        if (counter > 0) {
            //Oh no, we're not processing fast enough. This means problems...
            discarded++;
            NSLog(@"Processing too slow, skipping point, this corrupts sensor input temporarily!");
            return;
        }
        */
        counter++;
       if (sample < nrSamples) {
            [deviceMotionArray addObject:deviceMotion];
            sample++;
            //send this sample so others can listen to the data
            NSTimeInterval timestamp = deviceMotion.timestamp + timestampOffset;
            NSDictionary* data = [NSDictionary dictionaryWithObjectsAndKeys:
                                  deviceMotion, @"data",
                                  [NSNumber numberWithDouble:timestamp], @"timestamp",
                                  nil];
            NSNotification* notification = [NSNotification notificationWithName:kCSNewMotionDataNotification object:self userInfo:data];
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
        //if we've sampled enough
        if (sample >= nrSamples) {
            //signal that we're done collecting
            [dataCollectedCondition broadcast];
        }

        counter--;
    };
    motionManager.deviceMotionUpdateInterval = 1./frequency;
    [dataCollectedCondition lock];
    //[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue:operations withHandler:deviceMotionHandler];
    //[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXMagneticNorthZVertical toQueue:operations withHandler:deviceMotionHandler];
    [motionManager startDeviceMotionUpdatesToQueue:operations withHandler:deviceMotionHandler];

    NSDate* timeout = [NSDate dateWithTimeIntervalSinceNow:1.0/frequency * nrSamples * 2 + 1];
    while (sample < nrSamples && [timeout timeIntervalSinceNow] > 0) {
        //wait until all data collected, or a timeout
        NSTimeInterval timeout = MAX(1.0/frequency * nrSamples * 2 + 1, 0.1);
        [dataCollectedCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    }
    //[motionManager performSelectorOnMainThread:@selector(stopDeviceMotionUpdates) withObject:nil waitUntilDone:YES];
    [motionManager stopDeviceMotionUpdates];
    [dataCollectedCondition unlock];


    if (sample < nrSamples) {
        NSLog(@"Error while polling the motion sensors.");
        [motionManager stopDeviceMotionUpdates];
        return;
    }

    NSTimeInterval timestamp = ((CMDeviceMotion*)[deviceMotionArray objectAtIndex:0]).timestamp + timestampOffset;
    
    //either send all samples, or just the first
    BOOL rawSamples = NO, stats = YES;
    BOOL burst = nrSamples > 1;
    
    if (rawSamples)
        [self commitRawSamples:deviceMotionArray];
    else {
        NSRange range = NSMakeRange(0, 1);
        [self commitRawSamples:[deviceMotionArray subarrayWithRange:range]];
    }

    if (stats) {
        [self commitMotionFeaturesForSamples:deviceMotionArray withTimestamp:timestamp];
    }

    if (burst) {
        [self commitBurst:deviceMotionArray];
    }
}

- (void) commitMotionFeaturesForSamples:(NSArray*)deviceMotionArray withTimestamp:(NSTimeInterval) timestamp {
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
    [[CSSensorStore sharedSensorStore] addSensor:motionEnergySensor];
    [[CSSensorStore sharedSensorStore] addSensor:motionFeaturesSensor];
    
    //commit motion energy
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(magnitudeAvg, 3), @"value",
                                        CSroundedNumber(timestamp, 3),@"date",
                                        nil];
    [motionEnergySensor.dataStore commitFormattedData:valueTimestampPair forSensorId:motionEnergySensor.sensorId];
    
    NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
							CSroundedNumber(magnitudeAvg, 3), accelerationAvg,
							CSroundedNumber(magnitudeStddev, 3), accelerationStddev,
							//@"", accelerationKurtosis,
							CSroundedNumber(totalRotAvg, 3), rotationAvg,
							CSroundedNumber(totalRotStddev, 3), rotationStddev,
							//@"", rotationKurtosis,
							nil];
    
    valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        value, @"value",
                                        CSroundedNumber(timestamp, 3),@"date",
                                        nil];
    [motionFeaturesSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:motionFeaturesSensor.sensorId];
}

- (void) commitBurst:(NSArray*)deviceMotionArray {
    BOOL hasOrientation = orientationSensor != nil && orientationSensor.isEnabled;
    BOOL hasAccelerometer = accelerometerSensor != nil && accelerometerSensor.isEnabled;
    BOOL hasAcceleration = accelerationSensor != nil && accelerationSensor.isEnabled;
    BOOL hasRotation = rotationSensor != nil && rotationSensor.isEnabled;
    
    NSTimeInterval timestamp = ((CMDeviceMotion*)[deviceMotionArray objectAtIndex:0]).timestamp + timestampOffset;
    NSTimeInterval timestampEnd = ((CMDeviceMotion*)[deviceMotionArray lastObject]).timestamp + timestampOffset;
    NSTimeInterval dt = timestampEnd - timestamp;

    //Commit samples for the sensors
    if (hasOrientation) {
        NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:deviceMotionArray.count];
        
        [deviceMotionArray enumerateObjectsUsingBlock:^(CMDeviceMotion* motion, NSUInteger index, BOOL* stop) {
            NSNumber* pitch = CSroundedNumber(motion.attitude.pitch * radianInDegrees, 3);
            NSNumber* roll = CSroundedNumber(motion.attitude.roll * radianInDegrees, 3);
            double yawPrimitive = motion.attitude.yaw * radianInDegrees;
            if (yawPrimitive < 0)
                yawPrimitive += 360;
            NSNumber* yaw = CSroundedNumber(yawPrimitive, 3);
            [values addObject:[NSArray arrayWithObjects:pitch,roll,yaw, nil]];
        }];
        
        NSNumber* sampleInterval = CSroundedNumber(dt * 1000.0 / [deviceMotionArray count], 0);
        NSString* header = [NSString stringWithFormat:@"%@,%@,%@", attitudePitchKey, attitudeRollKey, attitudeYawKey];
        NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                               values, @"values",
                               header, @"header",
                               sampleInterval, @"interval",
                               nil];
        [CSSensePlatform addDataPointForSensor:kCSSENSOR_ORIENTATION_BURST displayName:nil description:nil dataType:kCSDATA_TYPE_JSON jsonValue:value timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
        
    }

    if (hasAccelerometer) {
        NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:deviceMotionArray.count];
        
        [deviceMotionArray enumerateObjectsUsingBlock:^(CMDeviceMotion* motion, NSUInteger index, BOOL *stop) {
            NSNumber* x = CSroundedNumber((motion.gravity.x + motion.userAcceleration.x) * G, 3);
            NSNumber* y = CSroundedNumber((motion.gravity.y + motion.userAcceleration.y) * G, 3);
            //z-axis is in other direction in CommonSense (thanks Android!)
            NSNumber* z = CSroundedNumber(-(motion.gravity.z + motion.userAcceleration.z) * G, 3);
            [values addObject:[NSArray arrayWithObjects:x,y,z, nil]];
        }];

        NSNumber* sampleInterval = CSroundedNumber(dt * 1000.0 / [deviceMotionArray count], 0);
        NSString* header = [NSString stringWithFormat:@"%@,%@,%@", CSaccelerationXKey, CSaccelerationYKey, CSaccelerationZKey];
        NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                               values, @"values",
                               header, @"header",
                               sampleInterval, @"interval",
                                nil];

        [CSSensePlatform addDataPointForSensor:kCSSENSOR_ACCELEROMETER_BURST displayName:nil description:nil dataType:kCSDATA_TYPE_JSON jsonValue:value timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    }
    
    if (hasAcceleration) {
        NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:deviceMotionArray.count];
        
        [deviceMotionArray enumerateObjectsUsingBlock:^(CMDeviceMotion* motion, NSUInteger index, BOOL *stop) {
            NSNumber* x = CSroundedNumber(motion.userAcceleration.x * G, 3);
            NSNumber* y = CSroundedNumber(motion.userAcceleration.y * G, 3);
            //z-axis is in other direction in CommonSense (thanks Android!)
            NSNumber* z = CSroundedNumber(-motion.userAcceleration.z * G, 3);
            [values addObject:[NSArray arrayWithObjects:x,y,z, nil]];
        }];
        
        NSNumber* sampleInterval = CSroundedNumber(dt * 1000.0 / [deviceMotionArray count], 0);
        NSString* header = [NSString stringWithFormat:@"%@,%@,%@", CSaccelerationXKey, CSaccelerationYKey, CSaccelerationZKey];
        NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                               values, @"values",
                               header, @"header",
                               sampleInterval, @"interval",
                               nil];

        [CSSensePlatform addDataPointForSensor:kCSSENSOR_ACCELERATION_BURST displayName:nil description:nil dataType:kCSDATA_TYPE_JSON jsonValue:value timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    }
    
    if (hasRotation) {
        NSMutableArray* values = [[NSMutableArray alloc] initWithCapacity:deviceMotionArray.count];
        
        [deviceMotionArray enumerateObjectsUsingBlock:^(CMDeviceMotion* motion, NSUInteger index, BOOL* stop) {
            NSNumber* pitch = CSroundedNumber(motion.rotationRate.x * radianInDegrees, 3);
            NSNumber* roll = CSroundedNumber(motion.rotationRate.y * radianInDegrees, 3);
            NSNumber* yaw = CSroundedNumber(motion.rotationRate.z * radianInDegrees, 3);
            [values addObject:[NSArray arrayWithObjects:pitch,roll,yaw, nil]];
        }];
        
        NSNumber* sampleInterval = CSroundedNumber(dt * 1000.0 / [deviceMotionArray count], 0);
        NSString* header = [NSString stringWithFormat:@"%@,%@,%@", attitudePitchKey, attitudeRollKey, attitudeYawKey];
        NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                               values, @"values",
                               header, @"header",
                               sampleInterval, @"interval",
                               nil];

        [CSSensePlatform addDataPointForSensor:kCSSENSOR_ROTATION_BURST displayName:nil description:nil dataType:kCSDATA_TYPE_JSON jsonValue:value timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    }
}

- (void) commitRawSamples:(NSArray*) deviceMotionArray {
    for (size_t i = 0; i < [deviceMotionArray count]; i++) {
        CMDeviceMotion* motion = [deviceMotionArray objectAtIndex:i];
        [self commitRawSample:motion];
    }
}

- (void) commitRawSample:(CMDeviceMotion*) motion {
    BOOL hasOrientation = orientationSensor != nil && orientationSensor.isEnabled;
    BOOL hasAccelerometer = accelerometerSensor != nil && accelerometerSensor.isEnabled;
    BOOL hasAcceleration = accelerationSensor != nil && accelerationSensor.isEnabled;
    BOOL hasRotation = rotationSensor != nil && rotationSensor.isEnabled;
    
    NSTimeInterval timestamp = motion.timestamp + timestampOffset;
    
    
    //Commit samples for the sensors
    if (hasOrientation) {
        CMAttitude* attitude = motion.attitude;
        //make compass value
        double yaw = attitude.yaw * radianInDegrees;
        if (yaw < 0) yaw += 360;
        
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(attitude.pitch * radianInDegrees, 3), attitudePitchKey,
                                        CSroundedNumber(attitude.roll * radianInDegrees, 3), attitudeRollKey,
                                        CSroundedNumber(yaw, 3), attitudeYawKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newItem, @"value",
                                            CSroundedNumber(timestamp, 3), @"date",
                                            nil];
        [orientationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:orientationSensor.sensorId];
        
    }
    
    
    if (hasAccelerometer) {
        double x = motion.gravity.x + motion.userAcceleration.x;
        double y = motion.gravity.y + motion.userAcceleration.y;
        //z-axis is in other direction in CommonSense (thanks Android!)
        double z = -(motion.gravity.z + motion.userAcceleration.z);
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(x * G,3), CSaccelerationXKey,
                                        CSroundedNumber(y * G, 3), CSaccelerationYKey,
                                        CSroundedNumber(z * G, 3), CSaccelerationZKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newItem, @"value",
                                            CSroundedNumber(timestamp, 3),@"date",
                                            nil];
        
        [accelerometerSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerometerSensor.sensorId];
        
    }
    
    if (hasAcceleration) {
        double x = motion.userAcceleration.x * G;
        double y = motion.userAcceleration.y * G;
        //z-axis is in other direction in CommonSense (thanks Android!)
        double z = -motion.userAcceleration.z * G;
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(x, 3), CSaccelerationXKey,
                                        CSroundedNumber(y, 3), CSaccelerationYKey,
                                        CSroundedNumber(z, 3), CSaccelerationZKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newItem, @"value",
                                            CSroundedNumber(timestamp, 3),@"date",
                                            nil];
        [accelerationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:accelerationSensor.sensorId];
    }
    
    if (hasRotation) {
        double pitch = motion.rotationRate.x * radianInDegrees;
        double roll = motion.rotationRate.y * radianInDegrees;
        double yaw = motion.rotationRate.z * radianInDegrees;
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(pitch, 3), attitudePitchKey,
                                        CSroundedNumber(roll, 3), attitudeRollKey,
                                        CSroundedNumber(yaw, 3), attitudeYawKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newItem, @"value",
                                            CSroundedNumber(timestamp, 3),@"date",
                                            nil];
        [rotationSensor.dataStore commitFormattedData:valueTimestampPair forSensorId:rotationSensor.sensorId];
    }
}

- (void) settingChanged: (NSNotification*) notification {
    @try {
        CSSetting* setting = notification.object;
        NSLog(@"Spatial: setting %@ changed to %@.", setting.name, setting.value);
        if ([setting.name isEqualToString:kCSSpatialSettingInterval]) {
            interval = [setting.value doubleValue];
        } else if ([setting.name isEqualToString:kCSSpatialSettingFrequency]) {
            frequency = [setting.value doubleValue];
        } else if ([setting.name isEqualToString:kCSSpatialSettingNrSamples]) {
            nrSamples = [setting.value intValue];
        }

        //restart
        if (enableCounter > 0) {
            [self schedulePollWithInterval:interval];
        }
    }
    @catch (NSException * e) {
        NSLog(@"spatial provider: Exception thrown while changing setting: %@", e);
    }
}

- (void) schedulePollWithInterval:(NSTimeInterval) newInterval {
    void (^innerSchedule)() = ^() {
        [motionManager stopDeviceMotionUpdates];
        @synchronized(pollTimerLock) {
            if (pollTimerGCD) {
                dispatch_source_cancel(pollTimerGCD);
            }
            uint64_t leeway = newInterval * 0.3 * NSEC_PER_SEC; //30% leeway
            pollTimerGCD = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, pollTimerQueueGCD);
            dispatch_source_set_event_handler(pollTimerGCD, ^{
                [self schedulePoll];
            });
            
            dispatch_source_set_timer(pollTimerGCD, dispatch_time(DISPATCH_TIME_NOW, newInterval * NSEC_PER_SEC), newInterval * NSEC_PER_SEC, leeway);
            dispatch_resume(pollTimerGCD);
        }
    };

    bool newContinuous = nrSamples / frequency >= newInterval - 1;
    if (continuous && newContinuous) {
        [self schedulePoll];
    } else if (!continuous && newContinuous) {
        [self stopPolling];
        continuous = YES;
        [self schedulePoll];
    } else if (continuous && !newContinuous) {
        continuous = NO;
        innerSchedule();
    } else { //!continuous && !newContinuous
        innerSchedule();
    }
}

- (void) stopPolling {
    continuous = NO;
    [motionManager stopDeviceMotionUpdates];
    @synchronized(pollTimerLock) {
        if (pollTimerGCD) {
            dispatch_source_cancel(pollTimerGCD);
            pollTimerGCD = NULL;
        }
    }
}

- (void) incEnable {
    enableCounter += 1;
    if (enableCounter == 1) {
        [motionManager stopDeviceMotionUpdates];
        [self schedulePollWithInterval:interval];
    }
}

- (void) decEnable {
    if (enableCounter > 0) {
        enableCounter -= 1;
        if (enableCounter == 0) {
            [self stopPolling];
        }
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [operations cancelAllOperations];
}

@end
