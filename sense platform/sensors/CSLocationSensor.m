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
	int accuracyPreference;
	NSMutableArray* samples;
    
    NSTimer* newSampleTimer;
    CLLocation* previousLocation;
}
//constants
static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* altitudeKey = @"altitude";
static NSString* horizontalAccuracyKey = @"accuracy";
static NSString* verticalAccuracyKey = @"vertical accuracy";
static NSString* speedKey = @"speed";
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
								@"float", longitudeKey,
								@"float", latitudeKey,
								@"float", altitudeKey,
								@"float", horizontalAccuracyKey,
								@"float", verticalAccuracyKey,
								@"float", speedKey,
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
        locationManager.activityType = CLActivityTypeOther;
        locationManager.pausesLocationUpdatesAutomatically = NO;
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeLocation] object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingChanged:) name:[CSSettings settingChangedNotificationNameForType:@"adaptive"] object:nil];
		
		samples = [[NSMutableArray alloc] initWithCapacity:maxSamples];
        previousLocation = nil;
        newSampleTimer = nil;
	}
	return self;
}

// Newer delegate method
- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    for (CLLocation* location in locations) {
        [self locationManager:manager updateToLocation: location fromLocation: nil];
    }
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
    updateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation {

    if (isEnabled == NO) {
        return;
    }
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
	
	double timestamp = [newLocation.timestamp timeIntervalSince1970];
	
	NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
										newItem, @"value",
										CSroundedNumber(timestamp, 3), @"date",
										nil];
	[dataStore commitFormattedData:valueTimestampPair forSensorId:self.sensorId];
    
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed with error %@", error);
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling location sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	if (enable) {
		@try {
			locationManager.desiredAccuracy = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy] intValue];
		} @catch (NSException* e) {
			NSLog(@"Exception setting position accuracy: %@", e);
		}
		[samples removeAllObjects];
        //NOTE: using significant location updates doesn't allow the phone to sense while running in the background
        [locationManager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
        [locationManager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
	}
	else {
        [newSampleTimer invalidate];
        [locationManager performSelectorOnMainThread:@selector(stopUpdatingLocation) withObject:nil waitUntilDone:YES];
        [locationManager performSelectorOnMainThread:@selector(stopMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
		//[locationManager stopUpdatingLocation];
        //as this needs to be enabled to run in the background, rather switch to the lowest accuracy
        //locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		[samples removeAllObjects];
	}
	isEnabled = enable;
}

- (void) setBackgroundRunningEnable:(BOOL) enable {
    if (enable) {
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
		} else if ([setting.name isEqualToString:@"interval"]) {
        } else if ([setting.name isEqualToString:@"locationAdaptive"]) {
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