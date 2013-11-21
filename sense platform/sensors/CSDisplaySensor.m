//
//  CSDisplaySensor.m
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSDisplaySensor.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"
#import "CSSensePlatform.h"

@implementation CSDisplaySensor

static NSString* screenKey = @"screen";
// pointer to it's self
id refToSelf;
// flags for seperation of lock/unlock events
int displayCompleteFlag = 0;
int displayLockStateFlag = 0;
int enableFlag = 0;

- (NSString*) name {return kCSSENSOR_SCREEN_STATE;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}
static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo);

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", screenKey,
							nil];
	//make string, as per spec
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			kCSDATA_TYPE_JSON, @"data_type",
            jsonString, @"data_structure",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
        refToSelf = self;
	}
	return self;
}


- (void) commitDisplayState:(BOOL) isScreenTurnedOn {
    if (isEnabled) {
        NSString* value = isScreenTurnedOn ? @"on" : @"off";
        
        NSNumber* timestamp = CSroundedNumber([[NSDate date] timeIntervalSince1970], 3);
        
        NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        value, screenKey,
                                        nil];
        
        NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                            newItem, @"value",
                                            timestamp,@"date",
                                            nil];
        
        [dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
    }
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ %@", enable ? @"Enabling":@"Disabling", [self name]);

	isEnabled = enable;
    
    if (enable) {
        if (enableFlag < 1) {
        //register for notifications...
        //as this one is only committed when it changes, commit current value
        
        // register to the darwin notificaitons
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        (__bridge const void *)(self), // observer
                                        displayStatusChanged, // callback
                                        CFSTR("com.apple.springboard.lockcomplete"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        (__bridge const void *)(self), // observer
                                        displayStatusChanged, // callback
                                        CFSTR("com.apple.springboard.lockstate"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
        enableFlag = 1;
        }
    } else {
        enableFlag = -1;
        // unregister from the darwin notifications
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), NULL, NULL);
    }
}

- (void) dealloc {
	self.isEnabled = NO;
}

@end

//call back for darwin notifications
static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    // the "com.apple.springboard.lockcomplete" notification will always come after the "com.apple.springboard.lockstate" notification
    CFStringRef nameCFString = (CFStringRef)name;
    NSString *lockState = (__bridge NSString*)nameCFString;
    //NSLog(@"Darwin notification: %@",name);
    BOOL display = FALSE;
    
    if([lockState isEqualToString:@"com.apple.springboard.lockcomplete"] && displayCompleteFlag == 0)
    {
        displayCompleteFlag = 1;
    }
    else if ([lockState isEqualToString:@"com.apple.springboard.lockstate"] && displayCompleteFlag == 1)
    {
        NSLog(@"DISPLAY OFF\n");
        display = FALSE;
        displayCompleteFlag = 0;
        if (enableFlag > 0) {
            [refToSelf commitDisplayState:display];
        }
    }
    else if ([lockState isEqualToString:@"com.apple.springboard.lockstate"] && displayCompleteFlag == 0) {
        NSLog(@"DISPLAY ON\n");
        displayCompleteFlag = 0;
        display = TRUE;
        if (enableFlag > 0) {
            [refToSelf commitDisplayState:display];
        }
    }
    
}