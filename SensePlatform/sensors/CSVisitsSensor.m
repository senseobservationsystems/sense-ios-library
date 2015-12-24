//
//  CSVisitsSensor.m
//  SensePlatform
//
//  Created by Joris Janssen on 26/02/15.
//
//

#import "CSVisitsSensor.h"
#import "CSDataStore.h"
#import "Formatting.h"
#import "CSSensorStore.h"


@implementation CSVisitsSensor

static NSString* longitudeKey = @"longitude";
static NSString* latitudeKey = @"latitude";
static NSString* accuracyKey = @"accuracy";
static NSString* eventKey = @"event";

	
- (NSString*) name {return kCSSENSOR_VISITS;}
- (NSString*) deviceType {return [self name];}

+ (BOOL) isAvailable {
     return [[UIDevice currentDevice].systemVersion intValue] >= 8;
}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							@"string", eventKey,
							@"float", longitudeKey,
							@"float", latitudeKey,
							@"float", accuracyKey,
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
	}
	
	return self;
}

- (void) storeVisit: (CLVisit *) visit {
	if (isEnabled == NO) {
		return;
	}
	
	NSString *event;
	NSDate *eventDate;
	
	if ([[visit departureDate] isEqualToDate: [NSDate distantFuture]]) {
		// User has arrived, but not left, the location
		event = @"arrive";
		eventDate = [visit arrivalDate];
	} else {
		// The visit is complete, the user has left
		event = @"depart";
		eventDate = [visit departureDate];
	}
	
	double latitude = [visit coordinate].latitude;
	double longitude = [visit coordinate].longitude;
	double accuracy = [visit horizontalAccuracy];

	
	NSMutableDictionary* newItem = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									event, eventKey,
									CSroundedNumber(longitude, 8), longitudeKey,
									CSroundedNumber(latitude, 8), latitudeKey,
									CSroundedNumber(accuracy, 8), accuracyKey,
									nil];
    [self commitDataPointWithValue:newItem andTime:eventDate];
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	NSLog(@"%@ %@ sensor (id=%@).", enable ? @"Enabling":@"Disabling", [self class], self.sensorId);
	isEnabled = enable;
}


- (void) dealloc {
	self.isEnabled = NO;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
