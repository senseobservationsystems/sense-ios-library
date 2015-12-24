//
//  CSLocationSensor.m
//  SensePlatform
//
//  Created by Joris Janssen on 26/02/15.
//
//

#import "CSLocationSensor.h"
#import "CSDataStore.h"
#import "Formatting.h"

@implementation CSLocationSensor

static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* altitudeKey = @"altitude";
static NSString* horizontalAccuracyKey = @"accuracy";
static NSString* verticalAccuracyKey = @"vertical accuracy";
static NSString* speedKey = @"speed";

//constants
static const int maxSamples = 7;
static const int minDistance = 10; //meters
static const int minInterval = 60; //seconds

static CLLocation* lastAcceptedPoint;

NSMutableArray* samples;
CLLocation* previousLocation;

- (NSString*) name {return kCSSENSOR_LOCATION;}
- (NSString*) deviceType {return [self name];}

//some users might be surprised that the position sensor isn't available. So let's say it's always available, and let ios/user handle turning services on/off.
//+ (BOOL) isAvailable {return [CLLocationManager locationServicesEnabled];}
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
		
		samples = [[NSMutableArray alloc] initWithCapacity:maxSamples];
		previousLocation = nil;
	}
	
	return self;
}

- (BOOL) rejectNewLocationPoint: (CLLocation *) newLocation withDesiredAccuracy: (int) desiredAccuracy{
	
	/* filter on location accuracy */
	bool rejected = false;
	
	//remove least recent sample
	if ([samples count] >= maxSamples)
		[samples removeLastObject];
	
	//insert this sample at beginning
	[samples insertObject:[NSNumber numberWithDouble: newLocation.horizontalAccuracy] atIndex:0];
	
	//sort so we can calculate quantiles
	NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"self" ascending:YES];
	NSArray *sorters = [[NSArray alloc] initWithObjects:sorter, nil];
	NSArray *sortedSamples = [samples sortedArrayUsingDescriptors:sorters];
	
	
	//100m, or within desiredAccuracy is a good start
	int goodStartAccuracy = desiredAccuracy;
	if (goodStartAccuracy < 100) goodStartAccuracy = 100;
	int adaptedGoodEnoughAccuracy;
	
	//decide wether to accept the sample
	if ([samples count] >= maxSamples) {
		//we expect within 2* second quartile, this rejects outliers
		adaptedGoodEnoughAccuracy = [[sortedSamples objectAtIndex:(int)(maxSamples/2)] intValue] * 2;
		//NSLog(@"adapted: %d", adaptedGoodEnoughAccuracy);
		if (newLocation.horizontalAccuracy <= adaptedGoodEnoughAccuracy)
			;
		else
			rejected = YES;
	}
	else if ([samples count] < maxSamples && newLocation.horizontalAccuracy <= goodStartAccuracy)
		; //accept if we haven't collected many samples, but accuracy is alread quite good
	else
		rejected = YES; //reject sample
	
	/* filter points when not moving. This avoids a lot of unnecessary points to upload. Without this filter at best accuracy it will generate a point every second. */
	if (lastAcceptedPoint != nil) {
		double distance = [newLocation distanceFromLocation:lastAcceptedPoint];
		double interval = [newLocation.timestamp timeIntervalSinceDate:lastAcceptedPoint.timestamp];
		if (!(distance >= minDistance || interval >= minInterval || newLocation.horizontalAccuracy < lastAcceptedPoint.horizontalAccuracy))
			rejected = YES;
	}
	
	if(! rejected) {
		lastAcceptedPoint = newLocation;
	}
	
	return rejected;
}

- (BOOL) storeLocation: (CLLocation *) location withDesiredAccuracy: (int) desiredAccuracy{

	if ([self rejectNewLocationPoint: location withDesiredAccuracy:desiredAccuracy]) {
		return false;
	}
	
	if (isEnabled == NO) {
		return true;
	}
	
	double longitude = location.coordinate.longitude;
	double latitude = location.coordinate.latitude;
	double altitude = location.altitude;
	double horizontalAccuracy = location.horizontalAccuracy;
	double verticalAccuracy = location.verticalAccuracy;
	double speed = location.speed;
	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									CSroundedNumber(longitude, 8), longitudeKey,
									CSroundedNumber(latitude, 8), latitudeKey,
									CSroundedNumber(horizontalAccuracy, 8), horizontalAccuracyKey,
									nil];
	if (location.speed >=0) {
		[newItem setObject:CSroundedNumber(speed, 1) forKey:speedKey];
	}
	if (location.verticalAccuracy >= 0) {
		[newItem setObject:CSroundedNumber(altitude, 0) forKey:altitudeKey];
		[newItem setObject:CSroundedNumber(verticalAccuracy, 0) forKey:verticalAccuracyKey];
	}
    
    [self commitDataPointWithValue:newItem andTime:location.timestamp];
	return true;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	NSLog(@"%@ %@ sensor (id=%@).", enable ? @"Enabling":@"Disabling", [self class], self.sensorId);
	isEnabled = enable;
	[samples removeAllObjects];
}


- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
