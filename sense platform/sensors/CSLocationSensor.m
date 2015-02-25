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

#import "CSLocationSensor.h"
#import "CSSettings.h"
#import "math.h"
#import "CSDataStore.h"
#import "Formatting.h"

@implementation CSLocationSensor {
    CLLocationManager* locationManager;
    NSTimer *pauseLocationSamplingTimer;
    UIBackgroundTaskIdentifier bgTask;
	int accuracyPreference;
	NSMutableArray* samples;
    CLLocation* previousLocation;
    
    //the boolean to enable or disable the automated pausing of location updates
    bool cortexAutoPausingEnabled;
}

//constants
static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* altitudeKey = @"altitude";
static NSString* horizontalAccuracyKey = @"accuracy";
static NSString* verticalAccuracyKey = @"vertical accuracy";
static NSString* speedKey = @"speed";
static NSString* eventKey = @"event";
static NSString* headingKey = @"heading";
static const int maxSamples = 7;
static const int minDistance = 10; //meters
static const int minInterval = 60; //seconds

static CLLocation* lastAcceptedPoint;

- (NSString*) name {return kCSSENSOR_LOCATION;}
- (NSString*) deviceType {return [self name];}
//+ (BOOL) isAvailable {return [CLLocationManager locationServicesEnabled];}
//some users might be surprised that the position sensor isn't available. So let's say it's always available, and let ios/user handle turning services on/off.
+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
								@"string", eventKey,
								@"float", longitudeKey,
								@"float", latitudeKey,
								@"float", altitudeKey,
								@"float", horizontalAccuracyKey,
								@"float", verticalAccuracyKey,
								@"float", speedKey,
								@"float", headingKey,
								nil];
	
	//make string, as per spec
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:format options:0 error:&error];
	NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[self name], @"name",
				[self deviceType], @"device_type",
				@"", @"pager_type",
				@"json", @"data_type",
				json, @"data_structure",
				nil];
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
		
		samples = [[NSMutableArray alloc] initWithCapacity:maxSamples];
        previousLocation = nil;
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
 * Whenever a new heading update is detected, this function stores the heading data into a sensor
 */
- (void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading	{

	NSString *event = @"headingUpdate";
	NSDate *eventDate = [newHeading timestamp];
	
	double latitude = -1.0;
	double longitude = -1.0;
	double accuracy = 0.0;
	double speed = -1.0;
	double altitude = -1.0;
	double verticalAccuracy = 0.0;
	double heading = [newHeading trueHeading];
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									event, eventKey,
									CSroundedNumber(longitude, 8), longitudeKey,
									CSroundedNumber(latitude, 8), latitudeKey,
									CSroundedNumber(altitude, 8), altitudeKey,
									CSroundedNumber(accuracy, 8), horizontalAccuracyKey,
									CSroundedNumber(verticalAccuracy, 8), verticalAccuracyKey,
									CSroundedNumber(speed, 8), speedKey,
									CSroundedNumber(heading, 8), speedKey,
									nil];
	
	double timestamp = [eventDate timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										CSroundedNumber(timestamp, 3), @"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
}

/**
 * Whenever a new visit update (departure or arrival) is detected, this function stores the visit data into a sensor
 */
- (void) locationManager:(CLLocationManager *)manager didVisit:(CLVisit *)visit {
	
	NSString *event;
	NSDate *eventDate;
	
	if ([[visit departureDate] isEqualToDate: [NSDate distantFuture]]) {
		// User has arrived, but not left, the location
		event = @"arrival";
		eventDate = [visit arrivalDate];
	} else {
		// The visit is complete, the user has left
		event = @"departure";
		eventDate = [visit departureDate];
	}
	
	double latitude = [visit coordinate].latitude;
	double longitude = [visit coordinate].longitude;
	double accuracy = [visit horizontalAccuracy];
	double speed = 0.0;
	double altitude = -1.0;
	double verticalAccuracy = 0.0;
	double heading = -1.0;
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									event, eventKey,
									CSroundedNumber(longitude, 8), longitudeKey,
									CSroundedNumber(latitude, 8), latitudeKey,
									CSroundedNumber(altitude, 8), altitudeKey,
									CSroundedNumber(accuracy, 8), horizontalAccuracyKey,
									CSroundedNumber(verticalAccuracy, 8), verticalAccuracyKey,
									CSroundedNumber(speed, 8), speedKey,
									CSroundedNumber(heading, 8), headingKey,
									nil];
	
	double timestamp = [eventDate timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										CSroundedNumber(timestamp, 3), @"date",
										nil];
	
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    updateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {

    if (isEnabled == NO) {
        return;
    }
	
	NSString* event = @"location_update";
	double longitude = newLocation.coordinate.longitude;
	double latitude = newLocation.coordinate.latitude;
	double altitude = newLocation.altitude;
	double horizontalAccuracy = newLocation.horizontalAccuracy;
	double verticalAccuracy = newLocation.verticalAccuracy;
	double speed = newLocation.speed;
    
	
	/* filter on location accuracy */
    bool rejected = false;
	//remove least recent sample
	if ([samples count] >= maxSamples)
		[samples removeLastObject];
	//insert this sample at beginning
	[samples insertObject:[NSNumber numberWithDouble: horizontalAccuracy ] atIndex:0];
	
	//sort so we can calculate quantiles
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
	NSArray *sorters = [[NSArray alloc] initWithObjects:sorter, nil];
	NSArray *sortedSamples = [samples sortedArrayUsingDescriptors:sorters];

	
	//100m, or within desiredAccuracy is a good start
	int goodStartAccuracy = locationManager.desiredAccuracy;
	if (goodStartAccuracy < 100) goodStartAccuracy = 100;
    int adaptedGoodEnoughAccuracy;
	//decide wether to accept the sample
	if ([samples count] >= maxSamples) {
		//we expect within 2* second quartile, this rejects outliers
		adaptedGoodEnoughAccuracy = [[sortedSamples objectAtIndex:(int)(maxSamples/2)] intValue] * 2;
		//NSLog(@"adapted: %d", adaptedGoodEnoughAccuracy);
		if (horizontalAccuracy <= adaptedGoodEnoughAccuracy)
			;
		else
			rejected = YES;;
	}
	else if ([samples count] < maxSamples && horizontalAccuracy <= goodStartAccuracy)
		; //accept if we haven't collected many samples, but accuracy is alread quite good
	else 
		rejected = YES; //reject sample
    if (rejected)
        return;
    
    /* filter points when not moving. This avoids a lot of unnecessary points to upload. Without this filter at best accuracy it will generate a point every second. */
    if (lastAcceptedPoint != nil) {
        double distance = [newLocation distanceFromLocation:lastAcceptedPoint];
        double interval = [newLocation.timestamp timeIntervalSinceDate:lastAcceptedPoint.timestamp];
        if (!(distance >= minDistance || interval >= minInterval || newLocation.horizontalAccuracy < lastAcceptedPoint.horizontalAccuracy))
            return;
    }
    lastAcceptedPoint = newLocation;


	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									event, eventKey,
									CSroundedNumber(longitude, 8), longitudeKey,
									CSroundedNumber(latitude, 8), latitudeKey,
									CSroundedNumber(horizontalAccuracy, 8), horizontalAccuracyKey,
									nil];
	if (newLocation.speed >=0) {
		[newItem setObject:CSroundedNumber(speed, 1) forKey:speedKey];
	}
	if (newLocation.verticalAccuracy >= 0) {
		[newItem setObject:CSroundedNumber(altitude, 0) forKey:altitudeKey];
		[newItem setObject:CSroundedNumber(verticalAccuracy, 0) forKey:verticalAccuracyKey];
	}
	
	[newItem setObject:CSroundedNumber(-1.0, 0) forKey:headingKey];
	
	double timestamp = [newLocation.timestamp timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										CSroundedNumber(timestamp, 3), @"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    
    if(cortexAutoPausingEnabled) {
        
        NSLog(@"Pausing location sampling ...");
        
        // Schedule location manager to run again in 120 seconds
        UIApplication *app = [UIApplication sharedApplication];
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
            bgTask = UIBackgroundTaskInvalid;
            NSLog(@"End of tolerate time. Application should be suspended now if we do not ask more 'tolerance'");
        }];
        
        if (bgTask == UIBackgroundTaskInvalid) {
            NSLog(@"This application does not support background mode");
        } else {
            //if application supports background mode, we'll see this log.
            //NSLog(@"Application will continue to run in background");
        }
        
        [locationManager stopUpdatingLocation];
        pauseLocationSamplingTimer = [NSTimer scheduledTimerWithTimeInterval:180 target:self selector:@selector(turnOnLocationSampling)  userInfo:nil repeats:NO];
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
- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"%@ location sensor", enable ? @"Enabling":@"Disabling");
	if (enable) {
		@try {
			locationManager.desiredAccuracy = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy] intValue];
		} @catch (NSException* e) {
			NSLog(@"Exception setting position accuracy: %@", e);
		}
		
        //set this here instead of when the sensor is enabled as otherwise the cortex testscript won't work
        locationManager.pausesLocationUpdatesAutomatically = NO;
		
		[samples removeAllObjects];
		
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager performSelectorOnMainThread:@selector(requestAlwaysAuthorization) withObject:nil waitUntilDone:YES];
        }
		
        //NOTE: using only significant location updates doesn't allow the phone to sense while running in the background
        [locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
        [locationManager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		
		if([[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingRecordVisits] boolValue]) {
			[locationManager startMonitoringVisits];
		}
		else {
			[locationManager stopMonitoringVisits];
		}
		
		if([[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingRecordHeadingUpdates] boolValue]) {
			[locationManager startUpdatingHeading];
		}
		else {
			[locationManager stopUpdatingHeading];
		}
		
	}
	else {
        [pauseLocationSamplingTimer invalidate];
        [locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:NO];
        [locationManager performSelectorOnMainThread:@selector(stopMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		[locationManager stopUpdatingHeading];
		[locationManager stopMonitoringVisits];
		//[locationManager stopUpdatingLocation];
        //as this needs to be enabled to run in the background, rather switch to the lowest accuracy
        //locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		[samples removeAllObjects];
	}
	isEnabled = enable;
}

- (void) setBackgroundRunningEnable:(BOOL) enable {
    if (enable) {
        if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [locationManager performSelectorOnMainThread:@selector(requestAlwaysAuthorization) withObject:nil waitUntilDone:YES];
        }
        [locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
        [locationManager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
    } else {
        [locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
        [locationManager performSelectorOnMainThread:@selector(stopMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
    }
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
		} else if ([setting.name isEqualToString:kCSLocationSettingRecordVisits]) {
			//Setting for starting and stopping the monitoring of visits
			if([setting.value boolValue]) {[locationManager startMonitoringVisits];}
			else {[locationManager stopMonitoringVisits];}
		} else if ([setting.name isEqualToString:kCSLocationSettingRecordHeadingUpdates]) {
			//Setting for starting and stopping the monitoring of heading updates
			if([setting.value boolValue]) {[locationManager startUpdatingHeading];}
			else {[locationManager stopUpdatingHeading];}
		}

	}
	@catch (NSException * e) {
		NSLog(@"LocationSensor: Exception thrown while applying location settings: %@", e);
	}
}

- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}
@end