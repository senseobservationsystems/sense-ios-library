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
/* refToSelf, displayCompleteFlag, enableFlag need to be global since we use them in the callback function */
// Pointer to it's self to use in the call back function
id refToSelf;
// flag for seperation of lock/unlock events
BOOL displayCompleteFlag;

// flag to detect and control the screen state at the first time
typedef enum enableFlagTypes {
    SCREEN_SENSOR_DISABLED = 0,
    SCREEN_SENSOR_INIT = 1,
    SCREEN_SENSOR_ENABLED = 2
} enableFlagState;

enableFlagState enableFlag;

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
        displayCompleteFlag = NO;
        enableFlag = SCREEN_SENSOR_INIT;
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
	
    int appState = [UIApplication sharedApplication].applicationState;
	NSLog(@"%@ %@", enable ? @"Enabling":@"Disabling", [self name]);

	isEnabled = enable;
    
    if (enable) {
        //if (enableFlag < 1) {
        if (enableFlag != SCREEN_SENSOR_ENABLED) {
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
            enableFlag = SCREEN_SENSOR_ENABLED;
            // if app is in the foreground send that screen is on
            if (appState == 1) {
                [self commitDisplayState:TRUE];
            }
        }
    } else {
        enableFlag = SCREEN_SENSOR_DISABLED;
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
    BOOL display = NO;
    
    if([lockState isEqualToString:@"com.apple.springboard.lockcomplete"] && displayCompleteFlag == NO)
    {
        displayCompleteFlag = YES;
    }
    else if ([lockState isEqualToString:@"com.apple.springboard.lockstate"] && displayCompleteFlag == YES)
    {
        NSLog(@"DISPLAY OFF\n");
        display = NO;
        displayCompleteFlag = NO;
        if (enableFlag == SCREEN_SENSOR_ENABLED) {
            [refToSelf commitDisplayState:display];
        }
    }
    else if ([lockState isEqualToString:@"com.apple.springboard.lockstate"] && displayCompleteFlag == NO) {
        NSLog(@"DISPLAY ON\n");
        displayCompleteFlag = NO;
        display = YES;
        if (enableFlag == SCREEN_SENSOR_ENABLED) {
            [refToSelf commitDisplayState:display];
        }
    }
}
