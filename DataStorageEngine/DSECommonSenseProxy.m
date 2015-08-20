//
//  DSECommonSenseProxy.m
//  SensePlatform
//
//  Created by Joris Janssen on 16/08/15.
//
//

#import "DSECommonSenseProxy.h"
#import "NSData+GZIP.h"
#import "NSString+MD5Hash.h"
#import "NSString+Utils.h"
#import "DSEErrors.h"
#import "DSEHTTPRequestHelper.h"

static const NSString* kUrlBaseURLLive              = @"https://api.sense-os.nl";
static const NSString* kUrlBaseURLStaging           = @"http://api.staging.sense-os.nl";
static const NSString* kUrlAuthenticationLive       = @"https://auth-api.sense-os.nl/v1";
static const NSString* kUrlAuthenticationStaging    = @"http://auth-api.staging.sense-os.nl/v1";

static const NSString* kUrlLogin					= @"login";
static const NSString* kUrlLogout                   = @"logout";
static const NSString* kUrlSensorDevice             = @"device";
static const NSString* kUrlSensors                  = @"sensors";
static const NSString* kUrlUsers                    = @"users";
static const NSString* kUrlUploadMultipleSensors    = @"sensors/data";
static const NSString* kUrlData                     = @"data";
static const NSString* kUrlDevices                  = @"devices";

static const NSString* kUrlJsonSuffix               = @".json";

@implementation DSECommonSenseProxy 


- (id) initAndUseLiveServer: (BOOL) useLiveServer withAppKey: (NSString *) theAppKey {
	
	self = [super init];
	
	if(self) {
        appKey                 = theAppKey;
		requestTimeoutInterval = 10;			//Time out of 10 sec for every request

		if(useLiveServer) {
            urlBase     = (NSString *)kUrlBaseURLLive;
            urlAuth		= (NSString *)kUrlAuthenticationLive;
		} else {
            urlBase     = (NSString *)kUrlBaseURLStaging;
            urlAuth		= (NSString *)kUrlAuthenticationStaging;
		}
	}
	
	return self;
}


#pragma mark User (Public)

- (NSString *) loginUser: (NSString *) username andPassword: (NSString *) password andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:username] || [NSString isEmptyString:password]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", urlAuth, kUrlLogin]];
    NSDictionary* inputDict  = @{@"username": username,
								 @"password": [NSString MD5HashOf:password] };
    NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"POST" andSessionID:nil andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:inputDict withError:error];
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	return [DSEHTTPRequestHelper processResponseWithData:responseData andHTTPResponse:httpResponse andError:error andBlock:
			  ^{
				NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
				return [NSString stringWithFormat:@"%@",[responseDict valueForKey:@"session_id"]];
			  }];
}


- (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}

	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", urlAuth, kUrlLogout]];
	NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"GET" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:nil withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];

	return [DSEHTTPRequestHelper evaluateResponseWithData: responseData andHttpResponse: httpResponse andError:error];
}

/*
- (BOOL) deleteCurrentUserWithSessionID: (NSString*) sessionID AndError:(NSError **) error{
    //get user id
    NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@", urlAuth, kUrlUsers, @"current"]];
    NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"GET" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:nil withError:nil];
    
    NSHTTPURLResponse* httpResponse;
    NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
    
    
    //delete user
    url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", urlAuth, kUrlUsers]];
    urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"DELETE" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:nil withError:nil];
    
    NSHTTPURLResponse* httpResponse;
    NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
    
    return [DSEHTTPRequestHelper evaluateResponseWithData: responseData andHttpResponse: httpResponse andError:error];

}
*/


#pragma mark Sensors and Devices (Public)

- (NSDictionary *) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:name] || [NSString isEmptyString:deviceType] || [NSString isEmptyString:dataType]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	if(! dataStructure) {
		dataStructure = @"";
	}
	
	if(! displayName) {
		displayName = @"";
	}
	
	
	NSMutableDictionary *sensorDescription =  [NSMutableDictionary dictionaryWithObjectsAndKeys:
													name,			@"name",
													displayName,	@"display_name",
													deviceType,		@"device_type",
													@"",			@"pager_type",
													dataType,		@"data_type",
													dataStructure,	@"data_structure",
													nil];

	
	NSDictionary* inputDict  = [NSDictionary dictionaryWithObject:sensorDescription forKey:@"sensor"];
	NSURL *url               = [self makeCSRestUrlFor:kUrlSensors append:nil];
	NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:inputDict withError:error];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];

	NSString *sensorID = [DSEHTTPRequestHelper processResponseWithData:responseData andHTTPResponse:httpResponse andError:error andBlock:
	 ^{
		@try {
			NSString* location          = [httpResponse.allHeaderFields valueForKey:@"location"];
			NSArray* locationComponents = [location componentsSeparatedByString:@"/"];
			return [locationComponents objectAtIndex:[locationComponents count] -1];
		}
		@catch (NSException *exception) {
			NSLog(@"Exception while creating sensor %@: %@", sensorDescription, exception);
		}
	}];
	
	if(sensorID) {
		[sensorDescription setValue:sensorID forKey:@"sensor_id"];
		return sensorDescription;
	} else {
		return nil;
	}
}


- (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andError: (NSError **) error {

	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSString *params = @"&per_page=1000&details=full";
	return [self getListForURLAction:kUrlSensors withParams:params withResultKey:@"sensors" withSessionID:sessionID andError:error];
}


- (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSString *params = @"&per_page=1000&details=full";
	return [self getListForURLAction:kUrlDevices withParams:params withResultKey:@"devices" withSessionID:sessionID andError:error];
}


- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:csSensorID] || [NSString isEmptyString:csDeviceID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSDictionary *deviceDict =  [NSDictionary dictionaryWithObjectsAndKeys:	csDeviceID, @"id", nil];
	return [self addSensorWithID:csSensorID toDeviceWithDict:deviceDict andSessionID:sessionID andError:error];
}


- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithType: (NSString *) deviceType andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:deviceType] || [NSString isEmptyString:UUID] || [NSString isEmptyString:csSensorID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSDictionary *deviceDict =  [NSDictionary dictionaryWithObjectsAndKeys:	deviceType, @"type", UUID, @"uuid", nil];
	return [self addSensorWithID:csSensorID toDeviceWithDict:deviceDict andSessionID:sessionID andError:error];
}


#pragma mark Data (Public)

- (BOOL) postData: (NSArray *) data withSessionID: (NSString *) sessionID andError: (NSError **) error {

	if( (!error) || (!data) || [NSString isEmptyString:sessionID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSDictionary* inputDict = [NSDictionary dictionaryWithObjectsAndKeys:
								data, @"sensors", nil];

	NSURL *url               = [self makeCSRestUrlFor:kUrlUploadMultipleSensors append:nil];
	NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:inputDict withError:error];
	
    
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
    
	return [DSEHTTPRequestHelper evaluateResponseWithData:responseData andHttpResponse:httpResponse andError:error];
}


- (NSArray *) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || (!startDate) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:csSensorID]) {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}

	NSString *params = [NSString stringWithFormat:@"?per_page=1000&start_date=%f&end_date=%f&sort=DESC", [startDate timeIntervalSince1970], [[NSDate date] timeIntervalSince1970]];
	NSString *urlAction = [NSString stringWithFormat: @"%@/%@/%@", kUrlSensors, csSensorID, kUrlData];
	
	return [self getListForURLAction:urlAction withParams:params withResultKey:@"data" withSessionID:sessionID andError:error];
}


#pragma mark Private methods

/**
 Helper function for adding sensor to device based on a device dict instead of the type, UUID, and/or ID. 
 */
- (BOOL) addSensorWithID:(NSString *)csSensorID toDeviceWithDict:(NSDictionary *)deviceDict andSessionID: (NSString*) sessionID andError:(NSError *__autoreleasing *)error {
	
	if(!error)  {
		[NSException raise:@"InvalidInputParameters" format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSDictionary* inputDict	 = [NSDictionary dictionaryWithObject:deviceDict forKey:@"device"];
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat: @"%@/%@/%@/%@%@", urlBase, kUrlSensors, csSensorID, kUrlSensorDevice,kUrlJsonSuffix]];
	NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:inputDict withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	return [DSEHTTPRequestHelper evaluateResponseWithData: responseData andHttpResponse: httpResponse andError:error];
}


/**
 Helper function for getting a list from the cs-rest API
 */
- (NSArray *) getListForURLAction: (const NSString*) urlAction withParams: (NSString *) paramsString withResultKey: (NSString *) resultKey withSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	NSInteger page              = 0;
	NSMutableArray* resultsList = [[NSMutableArray alloc] init];
	NSHTTPURLResponse* httpResponse;
	NSDictionary* responseDict;
	
	do {
		NSString *params		 = [NSString stringWithFormat:@"?page=%li%@", (long)page, paramsString];
		NSURL *url               = [self makeCSRestUrlFor:urlAction append:params];
		NSURLRequest *urlRequest = [DSEHTTPRequestHelper createURLRequestTo:url withMethod:@"GET" andSessionID:sessionID andAppKey: appKey andTimeoutInterval: requestTimeoutInterval andInput:nil withError:nil];
		NSData* responseData     = [DSEHTTPRequestHelper doRequest:urlRequest andResponse:&httpResponse andError:error];
		responseDict			 = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
		
		if(*error) {
			break;
		} else if ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
			*error = [DSEHTTPRequestHelper createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
			break;
		} else {
			[resultsList addObjectsFromArray:[responseDict valueForKey:resultKey]];
			page++;
		}
		
	} while (responseDict.count == 1000);
	
	return resultsList;
}


//Make a url with the included action
- (NSURL*) makeCSRestUrlFor:(const NSString *) action append:(NSString *) appendix
{
	if([NSString isEmptyString:(NSString *)action]) {
		return nil;
	}
	
	if(! appendix) {
		appendix = @"";
	}
	
	NSString* url = [NSString stringWithFormat: @"%@/%@%@%@",
					 urlBase,
					 action,
					 kUrlJsonSuffix,
					 appendix];
	
	return [NSURL URLWithString:url];
}





@end
