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


- (id) initForLiveServer: (BOOL) useLiveServer withAppKey: (NSString *) theAppKey {
	
	self = [super init];
	
	if(self) {
        appKey                 = theAppKey;


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
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSURL *url               = [self makeUrlFor:kUrlLogin append:nil];
    NSDictionary* inputDict  = @{@"username": username,
								 @"password": [NSString MD5HashOf:password] };
	
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:nil andAppKey:appKey andInput:inputDict andResponse:&httpResponse andError:error];
	
	NSString *sessionID = [DSEHTTPRequestHelper processResponseWithData:responseData andHTTPResponse:httpResponse andError:error andBlock: ^{
				NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
				return [NSString stringWithFormat:@"%@",[responseDict valueForKey:@"session_id"]];
			  }];
	
	return sessionID;
}


- (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}

	NSURL *url = [self makeUrlFor:kUrlLogout append:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey:appKey andInput:nil andResponse:&httpResponse andError:error];

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
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
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
	NSURL *url               = [self makeUrlFor:kUrlSensors append:nil];

	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey:appKey andInput:inputDict andResponse:&httpResponse andError:error];

	NSString *sensorID = [DSEHTTPRequestHelper processResponseWithData:responseData andHTTPResponse:httpResponse andError:error andBlock:^{
		
									NSString* location = [httpResponse.allHeaderFields valueForKey:@"location"];
									if(location && location != (id)[NSNull null]) {
										
										NSArray* locationComponents = [location componentsSeparatedByString:@"/"];
										
										if (locationComponents.count > 0) {
											return [locationComponents objectAtIndex:[locationComponents count]-1];
										}
									}
									return (id)nil;
							}];
	
	if(sensorID && ![NSString isEmptyString:sensorID]) {
		[sensorDescription setValue:sensorID forKey:@"sensor_id"];
		return sensorDescription;
	} else {
		if(error && !*error) {
			*error = [DSEHTTPRequestHelper createErrorWithCode:400 andMessage:@"Could not get sensor ID from server response"];
		}
		return nil;
	}
}


- (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andError: (NSError **) error {

	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSString *params = @"&per_page=1000&details=full";
	return [self getListForURLAction:kUrlSensors withParams:params withResultKey:@"sensors" withSessionID:sessionID andError:error];
}


- (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSString *params = @"&per_page=1000&details=full";
	return [self getListForURLAction:kUrlDevices withParams:params withResultKey:@"devices" withSessionID:sessionID andError:error];
}


- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithType: (NSString *) deviceType andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:deviceType] || [NSString isEmptyString:UUID] || [NSString isEmptyString:csSensorID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}
	
	NSDictionary *deviceDict = [NSDictionary dictionaryWithObjectsAndKeys:	deviceType, @"type", UUID, @"uuid", nil];
	NSDictionary* inputDict	 = [NSDictionary dictionaryWithObject:deviceDict forKey:@"device"];
	NSString* urlAction		 = [NSString stringWithFormat: @"%@/%@/%@", kUrlSensors, csSensorID, kUrlSensorDevice];
	NSURL *url               = [self makeUrlFor:urlAction append:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey:appKey andInput:inputDict andResponse:&httpResponse andError:error];
	
	return [DSEHTTPRequestHelper evaluateResponseWithData: responseData andHttpResponse: httpResponse andError:error];
}


#pragma mark Data (Public)

- (BOOL) postData: (NSArray *) data withSessionID: (NSString *) sessionID andError: (NSError **) error {

	if( (!error) || (!data) || (data.count == 0) || [NSString isEmptyString:sessionID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}

	NSDictionary* inputDict  = [NSDictionary dictionaryWithObjectsAndKeys: data, @"sensors", nil];
	NSURL *url               = [self makeUrlFor:kUrlUploadMultipleSensors append:nil];

	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey:appKey andInput:inputDict andResponse:&httpResponse andError:error];
	
	return [DSEHTTPRequestHelper evaluateResponseWithData:responseData andHttpResponse:httpResponse andError:error];
}


- (NSArray *) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if( (!error) || (!startDate) || [NSString isEmptyString:sessionID] || [NSString isEmptyString:csSensorID]) {
		[NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
	}

	NSString *params = [NSString stringWithFormat:@"?per_page=1000&start_date=%f&end_date=%f&sort=DESC", [startDate timeIntervalSince1970], [[NSDate date] timeIntervalSince1970]];
	NSString *urlAction = [NSString stringWithFormat: @"%@/%@/%@", kUrlSensors, csSensorID, kUrlData];
	
	return [self getListForURLAction:urlAction withParams:params withResultKey:@"data" withSessionID:sessionID andError:error];
}


#pragma mark Private methods


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
		NSURL *url               = [self makeUrlFor:urlAction append:params];
		
		NSData *responseData	 = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"GET" andSessionID:sessionID andAppKey:appKey andInput:nil andResponse:&httpResponse andError:error];
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
- (NSURL*) makeUrlFor:(const NSString *) action append:(NSString *) appendix
{
	if([NSString isEmptyString:(NSString *)action]) {
		return nil;
	}
	
	if(! appendix) {
		appendix = @"";
	}
	
	NSString *url;
	
	if([action isEqualToString:(NSString *)kUrlLogin] || [action isEqualToString:(NSString *)kUrlLogout]) {
		url = [NSString stringWithFormat: @"%@/%@%@",
			   urlAuth,
			   action,
			   appendix];
	} else {
		url = [NSString stringWithFormat: @"%@/%@%@%@",
						 urlBase,
						 action,
						 kUrlJsonSuffix,
						 appendix];
	}
	

	
	return [NSURL URLWithString:url];
}

@end
