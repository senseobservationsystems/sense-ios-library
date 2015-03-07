//
//  CSStepCounterProcessorSensor.m
//  SensePlatform
//
//  Created by Pim Nijdam on 02/06/14.
//
//

#import "CSStepCounterProcessorSensor.h"
#import <CoreMotion/CMPedometer.h>
#import "CSDataStore.h"
#import "Formatting.h"

static NSString* CSCMLastStepCount = @"CSCMLastStepCount";
static NSString* stepsKey = @"total";
static const int SAMPLE_INTERVAL = 60;

@implementation CSStepCounterProcessorSensor {
    CMPedometer* stepCounter;
    NSOperationQueue* operations;

    long long lastStepCount; // current window step cout
    NSDate* lastDate; // start of current window

    NSDate* startDate;
    long long startStepCount; // store number of total step before the session start
    long long processedStepCount;
}

- (NSString*) name {return kCSSENSOR_STEP_COUNTER;}
- (NSString*) deviceType {return @"apple_motion_processor";}
+ (BOOL) isAvailable {return [CMPedometer isStepCountingAvailable];}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							//kCSDATA_TYPE_STRING, confidenceKey,
                            //kCSDATA_TYPE_STRING, activityKey,
							nil];
	//make string, as per spec
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			kCSDATA_TYPE_JSON, @"data_type",
			json, @"data_structure",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		stepCounter = [[CMPedometer alloc] init];
        operations = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
    
	if (enable) {
        //store the date of the activity
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        self->lastStepCount = [prefs integerForKey:CSCMLastStepCount];
        
        // todo preprocess to continue from last data point
        self->startStepCount = 0;
        self->processedStepCount = 0;
        
        //handle real-time step updates
        self->lastStepCount = 0;
        self->startDate = [NSDate date];
        self->lastDate = self->startDate;
        [stepCounter startPedometerUpdatesFromDate:self->startDate withHandler:^(CMPedometerData *pedometerData, NSError *error) {
            [self handlePushStepCountData:pedometerData];
        }];
    } else {
        [stepCounter stopPedometerUpdates];
    }

	isEnabled = enable;
}

/**
 * Unimplemented, method used to get steps data for when the app wasn't running.
 * A bit complex and maybe undesired.
 * @deprecated
 */
- (void) queryStepsFrom:(NSDate*)from to:(NSDate*)to withInterval:(NSTimeInterval) dt {
    // deprecated
}

/**
 * Function to handle when there is step count update, this will group the data into an interval 
 * and save to store
 * @param data data structure returned by CoreMotion
 **/
- (void) handlePushStepCountData:(CMPedometerData*) data {
    long long currentStepCount = [data.numberOfSteps longLongValue] - self->processedStepCount;
    
    if (currentStepCount == 0) { return; }
    
    NSDate* now = [NSDate date];
    
    if ([now timeIntervalSinceDate:self->lastDate] < SAMPLE_INTERVAL) {
        // last date is still in the minute, update lastStepCount
        self->lastStepCount += currentStepCount;
    } else {
        // last date is different window, persist last data point, update the new
        
        if (self->processedStepCount != 0) {
            long long totalStepCounter = self->startStepCount + processedStepCount;
            [self persistDataStep:self->lastStepCount totalCount:totalStepCounter date:self->lastDate];
        }
        
        self->lastStepCount = currentStepCount;
        self->lastDate = now;
    }

    self->processedStepCount += currentStepCount;
}

/**
 * Function to store step point to CSStorage
 **/
-(void) persistDataStep:(long long) stepCount totalCount:(long long) total date:(NSDate*) date {
    
    NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithLongLong:stepCount], stepsKey,
                           nil];
    NSTimeInterval timestamp = [date timeIntervalSince1970];
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        value, @"value",
                                        CSroundedNumber(timestamp, 3),@"date",
                                        nil];
    [self.dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
}

-(void) dealloc {
	self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
