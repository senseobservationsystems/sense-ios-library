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

#import "CSLocationProvider.h"
#import "CSSettings.h"
#import "math.h"
#import "CSDataStore.h"

@implementation CSLocationProvider {
    CLLocationManager* locationManager;
	//int accuracyPreference;

	CSLocationSensor *locationSensor;
	CSVisitsSensor *visitsSensor;
    
    //the boolean to enable or disable the automated pausing of location updates
    bool cortexAutoPausingEnabled;
	NSTimer *pauseLocationSamplingTimer;
	UIBackgroundTaskIdentifier bgTask;
}


- (id) init {
	self = [super init];
	if (self) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
        
		//TODO: check if this is the best type to pick
        locationManager.activityType = CLActivityTypeOther;
		
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeLocation] object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:@"adaptive"] object:nil];
		
		//init the sensors
		visitsSensor = [[CSVisitsSensor alloc] init];
		locationSensor = [[CSLocationSensor alloc] init];
		
		
		//listen enable/disable notifications for visits sensor
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visitsEnabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_VISITS] object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationsEnabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_VISITS] object:nil];
	}
	return self;
}

- (id) initWithLocationSensor: (CSLocationSensor *) lSensor andVisitsSensor: (CSVisitsSensor *) vSensor {
	self = [super init];
	if (self) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		
		//TODO: check if this is the best type to pick
		locationManager.activityType = CLActivityTypeOther;
		
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeLocation] object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:@"adaptive"] object:nil];
		
		visitsSensor = vSensor;
		locationSensor = lSensor;
		
		//listen enable/disable notifications for visits sensor
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visitsEnabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_VISITS] object:nil];
	}
	return self;
}

// Newer delegate method
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation* location in locations) {
        [self locationManager:manager updateToLocation: location fromLocation: nil];
    }
}

/**
 * Whenever a new visit update (departure or arrival) is detected, this function stores the visit data into a sensor
 */
- (void) locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
	[visitsSensor storeVisit:visit];
}



// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager updateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	
	bool accepted = [locationSensor storeLocation: newLocation withDesiredAccuracy:manager.desiredAccuracy];
	
    if(cortexAutoPausingEnabled && accepted){
		
        // Schedule location manager to run again in 120 seconds
        UIApplication *app = [UIApplication sharedApplication];
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        if (bgTask == UIBackgroundTaskInvalid) {
            NSLog(@"This application does not support background mode");
            return;
        }
        
        double timeInterval = 180;
        double timeLeftForBackground = app.backgroundTimeRemaining;
        //NSLog(@"Total time left in background:%f",timeLeftForBackground);
        if (timeLeftForBackground < timeInterval) {
            timeInterval = timeLeftForBackground - 5.0;
            NSLog(@"Time Interval Between Location Update:%f", timeInterval);
        }
        
        [locationManager stopUpdatingLocation];
		
		//TODO: make the interval a setting
		//TODO: check if the interval is not higher than the required sample frequency for location updates;
        pauseLocationSamplingTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(turnOnLocationSampling)  userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:pauseLocationSamplingTimer forMode:NSRunLoopCommonModes];
    }
    
}

- (void) turnOnLocationSampling {
    
    NSLog(@"Restarting location updates");
    [locationManager startUpdatingLocation];
    
    //NSLog(@"Background Time:%f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@", error);
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSString* statusString = @"Unknown";
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            statusString = @"authorized always";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"authorized when in use";
            break;
        case kCLAuthorizationStatusDenied:
            statusString = @"authorization denied";
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusString = @"authorization undetermined";
            break;
        case kCLAuthorizationStatusRestricted:
            statusString = @"authorization restricted";
            break;
    }
    NSLog(@"New location authorization: %@", statusString);
}


- (BOOL) isEnabled {
	return isEnabled;
}

- (void) setIsEnabled:(BOOL) enable {
	[self enableLocationUpdates:enable];
	isEnabled = enable;
}

- (void) enableLocationUpdates:(BOOL) enable {
	
	NSLog(@"%@ location provider", enable ? @"Enabling":@"Disabling");
	
	if (enable) {
		@try {
			locationManager.desiredAccuracy = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy] intValue];
		} @catch (NSException* e) {
			NSLog(@"Exception setting position accuracy: %@", e);
		}
		
		//set this here instead of when the sensor is enabled as otherwise the cortex testscript won't work
		locationManager.pausesLocationUpdatesAutomatically = NO;

		if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
			[locationManager performSelectorOnMainThread:@selector(requestAlwaysAuthorization) withObject:nil waitUntilDone:YES];
		}
		
		//NOTE: using only significant location updates doesn't allow the phone to sense while running in the background
		[locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
		[locationManager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
	}
	else {
		[pauseLocationSamplingTimer invalidate];
		[locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:NO];
		[locationManager performSelectorOnMainThread:@selector(stopMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
		//as this needs to be enabled to run in the background, rather switch to the lowest accuracy
		//locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	}
}

// provided for backwards compatibility
- (void) setBackgroundRunningEnable:(BOOL) enable {
	[self setIsEnabled:enable];
}

// when the location sensor gets enabled we should start location updates; when it gets disabled, we turn it back to the location providers setting
- (void) locationsEnabledChanged: (NSNotification*) notification {
	if(locationSensor.isEnabled) {
		[self enableLocationUpdates:locationSensor.isEnabled];
	} else {
		[self enableLocationUpdates:self.isEnabled];
	}
}

- (void) visitsEnabledChanged: (NSNotification*) notification {
	if(visitsSensor.isEnabled) {[locationManager performSelectorOnMainThread:@selector(startMonitoringVisits) withObject:nil waitUntilDone:YES];}
	else {[locationManager performSelectorOnMainThread:@selector(stopMonitoringVisits) withObject:nil waitUntilDone:YES];}
}

- (void) settingChanged: (NSNotification*) notification  {
	@try {
		CSSetting* setting = notification.object;
		NSLog(@"Location setting %@ changed to %@.", setting.name, setting.value);

		if ([setting.name isEqualToString:kCSLocationSettingAccuracy]) {
			locationManager.desiredAccuracy = [setting.value integerValue];
        } else if ([setting.name isEqualToString:kCSLocationSettingCortexAutoPausing]) {
            cortexAutoPausingEnabled = [setting.value boolValue];
        } else if ([setting.name isEqualToString:@"interval"]) {
        } else if ([setting.name isEqualToString:@"locationAdaptive"]) {
		}
	}
	@catch (NSException * e) {
		NSLog(@"LocationProvider: Exception thrown while applying location settings: %@", e);
	}
}

- (void) dealloc {
	//self.isEnabled = NO;
	[self setIsEnabled:NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end