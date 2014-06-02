//
//  CSActivityProcessorSensor.m
//  SensePlatform
//
//  Created by Pim Nijdam on 02/06/14.
//
//

#import "CSActivityProcessorSensor.h"
#import <CoreMotion/CoreMotion.h>
#import "CSDataStore.h"
#import "Formatting.h"

static NSString* CSCMMotionActivityLastDate = @"CSCMMotionActivityLastDate";

static const NSString* confidenceKey = @"confidence";
static const NSString* activityKey = @"activity";

@implementation CSActivityProcessorSensor {
    CMMotionActivityManager* motionActivityManager;
   	NSOperationQueue* operations;
}

- (NSString*) name {return kCSSENSOR_ACTIVITY;}
- (NSString*) deviceType {return @"apple_motion_processor";}
+ (BOOL) isAvailable {return [CMMotionActivityManager isActivityAvailable];}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							kCSDATA_TYPE_STRING, confidenceKey,
                            kCSDATA_TYPE_STRING, activityKey,
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
		motionActivityManager = [[CMMotionActivityManager alloc] init];
        operations = [[NSOperationQueue alloc] init];
	}
	return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {

	if (enable) {
        
        //query for the past activities
        NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
        NSTimeInterval timestamp = [prefs doubleForKey:CSCMMotionActivityLastDate];
        NSDate* startDate = [NSDate dateWithTimeIntervalSince1970:timestamp];

        NSDate* endDate = [NSDate date];
        CMMotionActivityQueryHandler activityQueryHandler = ^(NSArray* activities, NSError* error) {
            if (activities == nil || error != nil)
                return;
            for (CMMotionActivity* activity in activities) {
                 NSLog(@"query activity: %@", activity);
                [self handleActivity:activity];
            }
            NSLog(@"");
            
        };
        [motionActivityManager queryActivityStartingFromDate:startDate toDate:endDate toQueue:operations withHandler:activityQueryHandler];
        
        //handle real-time activity updates
        CMMotionActivityHandler activityHandler = ^(CMMotionActivity* activity) {
            if (activity == nil)
                return;
            NSLog(@"activity: %@", activity);
            [self handleActivity:activity];
            
        };
        [motionActivityManager startActivityUpdatesToQueue:operations withHandler:activityHandler];
    } else {
        [motionActivityManager stopActivityUpdates];
    }
	
	isEnabled = enable;
}

- (void) handleActivity:(CMMotionActivity*) activity {
    NSString* activityType = @"unknown";
    if (activity.walking)
        activityType = @"walking";
    if (activity.running)
        activityType = @"running";
    if (activity.automotive)
        activityType = @"automotive";
    //activities are not mutually exclusive, e.g. automotive and stationary can be true so check for stationary as the latest item.
    if (activity.stationary)
        activityType = @"idle";
    NSString* confidence = @"unknown";
    switch (activity.confidence) {
        case CMMotionActivityConfidenceLow:
            confidence = @"low";
            break;
        case CMMotionActivityConfidenceMedium:
            confidence = @"medium";
            break;
        case CMMotionActivityConfidenceHigh:
            confidence = @"high";
            break;
    }
    
    
    NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                           activityType, activityKey,
                           confidence, confidenceKey,
                           nil];
    NSTimeInterval timestamp = [activity.startDate timeIntervalSince1970];
    
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                          value, @"value",
                          CSroundedNumber(timestamp, 3),@"date",
                          nil];
    [self.dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    
    //store the date of the activity
    NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
    [prefs setDouble:timestamp forKey:CSCMMotionActivityLastDate];
    
}

-(void) dealloc {
	self.isEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end