//
//  ConnectionSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 4/29/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import "ConnectionSensor.h"
#import "Reachability.h"
#import "DataStore.h"

@implementation ConnectionSensor

- (NSString*) name {return @"connection type";}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//make string, as per spec
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"string", @"data_type",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		    internetReach = [Reachability reachabilityForInternetConnection];
		    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
	}
	return self;
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	NetworkStatus netStatus = [internetReach currentReachabilityStatus];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"none";  
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"mobile";
            break;
        }
        case ReachableViaWiFi:
        {
			statusString= @"wifi";
            break;
		}
    }
	
	
	NSNumber* timestamp = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										statusString, @"value",
										timestamp,@"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling connection type sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		[internetReach startNotifier];
		[self reachabilityChanged:nil];
	} else {
		[internetReach stopNotifier];
	}

	isEnabled = enable;
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

@end