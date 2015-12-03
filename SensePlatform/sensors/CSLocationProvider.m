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
#import "CoreLocation/CLLocationManager.h"
#import "CSSettings.h"
#import "math.h"
#import "CSDataStore.h"
#import "CSSensorStore.h"
#import "CSSensorConstants.h"

@implementation CSLocationProvider {
    CLLocationManager* locationManager;
	//int accuracyPreference;

	CSLocationSensor *locationSensor;
	CSVisitsSensor *visitsSensor;
    
	
    bool locationUpdatesAutoPausingEnabled;		//the boolean to enable or disable the automated pausing of location updates
	int autoPausingInterval;					//Interval to pause location updates when locationUpdatesAutoPausing is enabled.
	NSTimer *pauseLocationSamplingTimer;
	UIBackgroundTaskIdentifier bgTask;
}


- (id) init {
	self = [super init];
	if (self) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;
		
        //init the sensors
        visitsSensor = [[CSVisitsSensor alloc] init];
        locationSensor = [[CSLocationSensor alloc] init];
        
        [self initialize];
	}
	return self;
}

- (id) initWithLocationSensor: (CSLocationSensor *) lSensor andVisitsSensor: (CSVisitsSensor *) vSensor {
	self = [super init];
	if (self) {
		locationManager = [[CLLocationManager alloc] init];
		locationManager.delegate = self;

        visitsSensor = vSensor;
        locationSensor = lSensor;

        [self initialize];
	}
	return self;
}

- (void) initialize {
    
    //default values also set in the default settings like this
    locationUpdatesAutoPausingEnabled = FALSE;
    autoPausingInterval = 180;
    
    //TODO: check if this is the best type to pick
    locationManager.activityType = CLActivityTypeOther;
    
    //register for change in settings
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeLocation] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:@"adaptive"] object:nil];
    
    
    //listen enable/disable notifications for visits sensor
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visitsEnabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_VISITS] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationsEnabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:kCSSENSOR_VISITS] object:nil];
    
    // listen for enable notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setEnabledNotificationHandler:) name:kCSEnableLocationProvider object:nil];
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
	
    if(locationUpdatesAutoPausingEnabled && accepted){
		[self pauseLocationSampling];
	}
    
}

/**
 Schedules the location manager to stop updating locations and restart after 180 seconds.
 
 Note: Every background task should be properly stopped otherwise the app is killed. This is done in [self resumeLocationUpdates].
 */
- (void) pauseLocationSampling {
	
	//Start a background task
	UIApplication *app = [UIApplication sharedApplication];
	bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
		[self resumeLocationSampling];
		bgTask = UIBackgroundTaskInvalid;
	}];

	double timeInterval = autoPausingInterval;
	double timeLeftForBackground = [app backgroundTimeRemaining];
	
	// Check if we get a valid background task and time remaining value
	if( (timeLeftForBackground < 0) || (timeLeftForBackground > 10*60) || (bgTask == UIBackgroundTaskInvalid)) {
		[self resumeLocationSampling];
		return;
	}
	
	// Check if we have enough time remaining for
	if (timeLeftForBackground < timeInterval) {
		timeInterval = timeLeftForBackground - 20.0;
	}
	
	// Stop location updates
	[locationManager stopUpdatingLocation];
	
	//Start the timer to restart the location updates
	pauseLocationSamplingTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(resumeLocationSampling)  userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:pauseLocationSamplingTimer forMode:NSRunLoopCommonModes];
}


/**
 Resume location sampling and stop the background task.
 
 Note: This is used in conjunction with [self pauseLocationSampling].
 */
- (void) resumeLocationSampling {
    [locationManager startUpdatingLocation];
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
            [[NSNotificationCenter defaultCenter] postNotificationName:[CSSettings permissionGrantedForProvider:kCSLOCATION_PROVIDER] object:nil];
            break;
        case kCLAuthorizationStatusDenied:
            statusString = @"authorization denied";
            [[NSNotificationCenter defaultCenter] postNotificationName:[CSSettings permissionDeniedForProvider:kCSLOCATION_PROVIDER] object:nil];
            break;
        case kCLAuthorizationStatusNotDetermined:
            statusString = @"authorization undetermined";
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            statusString = @"authorized when in use";
            break;

        case kCLAuthorizationStatusRestricted:
            statusString = @"authorization restricted";
            break;
    }
    // remove unnecessary NSLog statement.
     NSLog(@"New location authorization: %@", statusString);
}


- (BOOL) isEnabled {
	return isEnabled;
}

// enabled the location provider
- (void) setIsEnabled:(BOOL) enable {
	[self enableLocationUpdates:enable];
	isEnabled = enable;
}

// notification handler for switching on the locationProvider to make the location provider run
- (void) setEnabledNotificationHandler: (NSNotification*) notification {
    NSLog(@"[LocationProvider] setEnabledNotificaiton received!");
    [self setIsEnabled: YES];
}

- (void) enableLocationUpdates:(BOOL) enable {
	
	NSLog(@"[LocationProvider] %@ location provider", enable ? @"Enabling":@"Disabling");
	
	if (enable && !isEnabled) {
       @try {
            locationManager.desiredAccuracy = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy] intValue];
		   //set this here instead of when the sensor is enabled as otherwise the cortex testscript won't work

		   locationManager.pausesLocationUpdatesAutomatically = NO;
		   
		   // make sure we have the correct permissions
		   [self requestPermission];
		   
		   //NOTE: using only significant location updates doesn't allow the phone to sense while running in the background
		   [locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
		   [locationManager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		   
		   
	   } @catch (NSException* e) {
		   NSLog(@"Exception in enabling location provider: %@", e);
	   }
    

	}
	else if (!enable && isEnabled) {
		[pauseLocationSamplingTimer invalidate];
		[locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:NO];
		[locationManager performSelectorOnMainThread:@selector(stopMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
		//as this needs to be enabled to run in the background, rather switch to the lowest accuracy
		//locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	}
}

- (void) requestPermission {
    // check to make sure we dont do this on iOS < 8
    if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        // check if we haven't already asked permissions
        if (!([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
            // request the permissions
            [locationManager performSelectorOnMainThread:@selector(requestAlwaysAuthorization) withObject:nil waitUntilDone:YES];
        }
    }
}

- (CLAuthorizationStatus) permissionState {
    return [CLLocationManager authorizationStatus];
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
            locationUpdatesAutoPausingEnabled = [setting.value boolValue];
		} else if ([setting.name isEqualToString:kCSLocationSettingAutoPausingInterval]) {
			autoPausingInterval = [setting.value intValue];
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