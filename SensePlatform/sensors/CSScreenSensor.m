//
//  CSScreenSensor.m
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSScreenSensor.h"
#import <UIKit/UIKit.h>
#import "CSDataStore.h"
#import "Formatting.h"
#import "CSSensePlatform.h"

static NSString* screenKey = @"screen";
/* refToSelf, displayCompleteFlag, enableFlag need to be global since we use them in the callback function.  NOTE: only works for one instance of CSScreenSensor! */
// Pointer to it's self to use in the call back function.
static id refToSelf;


// Indicates timestamp in seconds when the last lock complete event was received
double timeLockCompleteEvent;

// Timer to wait for a lockcomplete event
NSTimer *waitForLockCompleteEvent;

NSString* const kVALUE_IDENTIFIER_SCREEN_LOCKED = @"off";
NSString* const kVALUE_IDENTIFIER_SCREEN_UNLOCKED = @"on";
NSString* const kVALUE_IDENTIFIER_SCREEN_ONOFF_SWITCH = @"screenOnOffSwitch";

@implementation CSScreenSensor {

}

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
		timeLockCompleteEvent = 0.0;
	}
	return self;
}

- (void) commitDisplayState:(const NSString *) state {
    NSDate* time = [NSDate date];
    [self commitDataPointWithValue:state andTime:time];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
    UIApplicationState appState = [UIApplication sharedApplication].applicationState;
	NSLog(@"%@ %@", enable ? @"Enabling":@"Disabling", [self name]);

   
    if (enable && isEnabled == NO) {
        // register to the darwin notifications
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        (__bridge const void *)(self), // observer
                                        displayStatusChanged, // callback
                                        CFSTR("com.apple.springboard.lockcomplete"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
										(__bridge const void *)(self), // observer
										displayStatusChanged, // callback
										CFSTR("com.apple.springboard.hasBlankedScreen"), // event name
										NULL, // object
										CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        (__bridge const void *)(self), // observer
                                        displayStatusChanged, // callback
                                        CFSTR("com.apple.springboard.lockstate"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);

        //as this one is only committed when it changes, commit current value
        // if app is in the foreground send that screen is on
        if (appState == UIApplicationStateActive) {
            [self commitDisplayState:kVALUE_IDENTIFIER_SCREEN_UNLOCKED];
        }
    } else if (enable == NO && isEnabled == YES){
        // unregister from the darwin notifications
        CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), NULL, NULL);
    }
    
  	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
}


// Whenever no lockcomplete event was received, we assume the screen has been unlocked
- (void) lockcompleteNotReceived {
	[self commitDisplayState:kVALUE_IDENTIFIER_SCREEN_UNLOCKED];
}

@end


//Call back for darwin notifications. If there is a lockcomplete event the screen has been turned off. If there is a hasBlankedScreen event and no lockcomplete event 300 ms before or after, we assume the screen has turned on.
static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    NSString *eventIdentifier = (__bridge NSString*)(CFStringRef)name;
	
    if([eventIdentifier isEqualToString:@"com.apple.springboard.lockcomplete"])
    {
		//set display to off
		[refToSelf commitDisplayState:kVALUE_IDENTIFIER_SCREEN_LOCKED];
		
		//stop any timer that might be running
		if(waitForLockCompleteEvent) {
			[waitForLockCompleteEvent invalidate];
			waitForLockCompleteEvent = nil;
		}
		
		//update timeLockCompleteEvent
		timeLockCompleteEvent = [[NSDate date] timeIntervalSince1970];
    }
	else if ([eventIdentifier isEqualToString:@"com.apple.springboard.lockstate"]) {
		
		//start a timer to check for incoming lockcomplete events
		if([[NSDate date] timeIntervalSince1970] - timeLockCompleteEvent > 0.300) {
			waitForLockCompleteEvent = [NSTimer scheduledTimerWithTimeInterval:0.300 target:refToSelf selector:@selector(lockcompleteNotReceived) userInfo:nil repeats:NO];
		}
	} else if ([eventIdentifier isEqualToString:@"com.apple.springboard.hasBlankedScreen"]) {
		//TODO: what is this state? Should I remove this?
        //[refToSelf commitDisplayState:kVALUE_IDENTIFIER_SCREEN_ONOFF_SWITCH];
	}
}
