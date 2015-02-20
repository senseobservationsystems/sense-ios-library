//
//  CSSpatialProviderTest.m
//  SensePlatform
//
//  Created by Joris Janssen on 09/02/15.
//
//

#import "CSSpatialProviderTest.h"
#import "CSSpatialProvider.h"

@implementation CSSpatialProviderTest

CSSpatialProvider *spatialProvider;

- (void) setUp {
	spatialProvider = [[CSSpatialProvider alloc] initWithCompass:[[CSCompassSensor alloc] init] orientation:[[CSOrientationSensor alloc] init] accelerometer: [[CSAccelerometerSensor alloc] init] acceleration:[[CSAccelerationSensor alloc] init] rotation:[[CSRotationSensor alloc] init] jumpSensor:[[CSJumpSensor alloc] init]];
	
}

- (void) tearDown {
	
}

- (void) testPoll {
	
	dispatch_queue_t pollQueueGCD = dispatch_queue_create("com.sense.sense_platform.pollQueue", NULL);
	
	//Do some polling
	dispatch_async(pollQueueGCD, ^{
		@autoreleasepool {
				[spatialProvider poll];
		}
	});

	//And immediately do some polling again
	dispatch_async(pollQueueGCD, ^{
		@autoreleasepool {
			[spatialProvider poll];
		}
	});
	
	//And do some polling in another thread
	[spatialProvider poll];
	
	//If we get here, the polling didn't crash
	XCTAssertTrue(TRUE, @"Polling did crash somewhere");
}

@end
