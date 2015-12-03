//
//  CSStepCounterProcessorSensor.m
//  SensePlatform
//
//  Created by Pim Nijdam on 02/06/14.
//
//

#import "CSStepCounterProcessorSensor.h"
#import <CoreMotion/CoreMotion.h>
#import "CSDataStore.h"
#import "Formatting.h"
#import "CSSensePlatform.h"

static NSString* CSCMLastStepCount = @"CSCMLastStepCount";
static NSString* stepsKey = @"total";

@implementation CSStepCounterProcessorSensor {
    CMStepCounter* stepCounter;
    NSOperationQueue* operations;
    long long lastStepCount;
    //used from inside the query block, a bit ugly, it it does the job
    NSDate* startDate;
    NSDate* endDate;
}

- (NSString*) name {return kCSSENSOR_STEP_COUNTER;}
- (NSString*) deviceType {return @"apple_motion_processor";}
+ (BOOL) isAvailable {return [CMStepCounter isStepCountingAvailable];}


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
		stepCounter = [[CMStepCounter alloc] init];
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
        //handle real-time step updates
        CMStepUpdateHandler stepCounterHandler = ^(NSInteger steps, NSDate* date, NSError* error) {
            if (steps == 0 || error != nil)
                return;
            [self handleStepCount:lastStepCount + steps atDate:date];
        };
        self->lastStepCount = 0;
        [stepCounter startStepCountingUpdatesToQueue:operations updateOn:30 withHandler:stepCounterHandler];
    } else {
        [stepCounter stopStepCountingUpdates];
    }

	isEnabled = enable;
}

/* Obsolete, method used to get steps data for when the app wasn't running. A bit complex and maybe undesired.*/
- (void) queryStepsFrom:(NSDate*)from to:(NSDate*)to withInterval:(NSTimeInterval) dt {
    //use startDate and endDate from the block to keep track of the period.
    startDate = from;
    endDate = [startDate dateByAddingTimeInterval:dt];
    NSTimeInterval period = [to timeIntervalSinceDate:from];
    int noPeriods = ceil(period/dt);
    CMStepQueryHandler stepQueryHandler = ^(NSInteger steps, NSError* error) {
        if (error != nil)
            [self handleStepCount:steps atDate:endDate];
        startDate = endDate;
        endDate = [startDate dateByAddingTimeInterval:dt];
        
        NSLog(@"query steps: %li", (long)steps);
    };
    for (int i = 0; i < noPeriods; i++) {
        [stepCounter queryStepCountStartingFrom:startDate to:endDate toQueue:operations withHandler:stepQueryHandler];//
    }
}

- (void) handleStepCount:(long long) steps atDate:(NSDate*) date {
    NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithLongLong:steps], stepsKey,
                           nil];
//    NSTimeInterval timestamp = [date timeIntervalSince1970];
//    
//    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
//                                        value, @"value",
//                                        CSroundedNumber(timestamp, 3),@"date",
//                                        nil];
//    [self.dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    [self insertOrUpdateDataPointWithValue:value time:date];
    
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setInteger:(int)steps forKey:CSCMLastStepCount];
}

-(void) dealloc {
	self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
