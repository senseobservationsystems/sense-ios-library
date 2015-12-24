//
//  TimeZoneSensor.m
//  SensePlatform
//
//  Created by Pim Nijdam on 12/11/14.
//
//

#import "CSTimeZoneSensor.h"
#import "CSDataStore.h"
#import "Formatting.h"

@implementation CSTimeZoneSensor
static NSString* offsetKey = @"offset";
static NSString* idKey = @"id";

- (NSString*) name {return kCSSENSOR_TIMEZONE;}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
    //create description for data format. programmer: make SURE it matches the format used to send data
    NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
                            @"integer", offsetKey,
                            @"string", idKey,
                            nil];
    //make string, as per spec
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [self name], @"name",
            [self deviceType], @"device_type",
            @"", @"pager_type",
            @"json", @"data_type",
            jsonString, @"data_structure",
            nil];
}

- (id) init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
    //only react to changes
    //if (enable == isEnabled) return;
    
    NSLog(@"%@ %@", enable ? @"Enabling":@"Disabling", self.name);
    isEnabled = enable;
    
    if (enable) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(commitTimeZone:)
                                                     name:NSSystemTimeZoneDidChangeNotification object:nil];
        //as this one is only committed when it changes, commit current value
        [self commitTimeZone:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSSystemTimeZoneDidChangeNotification object:nil];
    }
}

- (void) commitTimeZone:(NSNotification*)notification {
    //get current time zone and offset
    NSTimeZone* localTimeZone = [NSTimeZone systemTimeZone];
    NSInteger secondsFromGmt = [localTimeZone secondsFromGMT];
    NSString* timeZoneString = localTimeZone.name;
    NSDictionary* value = @{offsetKey:@(secondsFromGmt), idKey:timeZoneString};
    NSLog(@"Timezone changed to %@ with offset %li", timeZoneString, (long)secondsFromGmt);

    [self commitDataPointWithValue:value andTime:[NSDate date]];
}

@end
