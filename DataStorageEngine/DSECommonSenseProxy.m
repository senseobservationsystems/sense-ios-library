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
#import "DSEErrors.h"

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
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: username] || [self isEmptyString: password]) {
		*error = [self createErrorWithCode:kErrorCodeInvalidUsernamePassword andMessage:@"Invalid usename or password"];
		return nil;
	}
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", urlAuth, kUrlLogin]];
    NSString *hashedPassword = [NSString MD5HashOf:password];
    NSDictionary* inputDict  = @{@"username": username,
								 @"password": hashedPassword };
    NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"POST" andSessionID:nil andInput:inputDict withError:error];

	if(*error) {
		return nil;
	}
	
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	if(*error) {
		return nil;
	} else if ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return nil;
	} else {
		NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
		if(*error) {
			return nil;
		} else {
			return [NSString stringWithFormat:@"%@",[responseDict valueForKey:@"session_id"]];
		}
	}
}

- (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: sessionID]) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Invalid sessionID"];
		return nil;
	}
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", urlAuth, kUrlLogout]];
	NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"GET" andSessionID:sessionID andInput:nil withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];

	if(*error) {
		return NO;
	} else if  ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return NO;
	} else {
		return YES;
	}
}

#pragma mark Sensors and Devices (Public)

- (NSDictionary *) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: sessionID] || [self isEmptyString: name] || [self isEmptyString: deviceType] || [self isEmptyString: dataType]) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Input parameters incomplete"];
		return nil;
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
	NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andInput:inputDict withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	if (*error) {
		return nil;
	} else if ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return nil;
	} else {
		@try {
            NSString* location          = [httpResponse.allHeaderFields valueForKey:@"location"];
            NSArray* locationComponents = [location componentsSeparatedByString:@"/"];
            NSString* sensorId          = [locationComponents objectAtIndex:[locationComponents count] -1];
			[sensorDescription setValue:sensorId forKey:@"sensor_id"];
		}
		@catch (NSException *exception) {
			NSLog(@"Exception while creating sensor %@: %@", sensorDescription, exception);
		}
		
		return sensorDescription;
	}
}

- (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	return [self getListForURLAction:kUrlSensors withSessionID:sessionID andError:error];
}

- (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	return [self getListForURLAction:kUrlDevices withSessionID:sessionID andError:error];
}

- (NSArray *) getListForURLAction: (const NSString*) urlAction withSessionID: (NSString *) sessionID andError: (NSError **) error {
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: sessionID]) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Invalid sessionID"];
		return nil;
	}
	
    NSInteger page              = 0;
    NSMutableArray* resultsList = [[NSMutableArray alloc] init];
	NSHTTPURLResponse* httpResponse;
	NSDictionary* responseDict;
	
	do {
		NSString* params         = [NSString stringWithFormat:@"?per_page=1000&details=full&page=%li", (long)page];
		NSURL *url               = [self makeCSRestUrlFor:urlAction append:params];
		NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"GET" andSessionID:sessionID andInput:nil withError:nil];
		NSData* responseData     = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
		responseDict			 = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
		
		if(*error) {
			break;
		} else if ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
			*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
			break;
		} else {
			[resultsList addObjectsFromArray:[responseDict valueForKey:@"sensors"]];
			page++;
		}
		
	} while (responseDict.count == 1000);
	
	return resultsList;
}

- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: sessionID] || [self isEmptyString:csDeviceID]) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Incomplete input parameters"];
		return nil;
	}
	
	NSDictionary *deviceDict =  [NSDictionary dictionaryWithObjectsAndKeys:	csDeviceID, @"id",
																			nil];
	NSDictionary* inputDict = [NSDictionary dictionaryWithObject:deviceDict forKey:@"device"];
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat: @"%@/%@/%@/%@%@", urlBase, kUrlSensors, csSensorID, kUrlSensorDevice,kUrlJsonSuffix]];
	NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andInput:inputDict withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	if(*error) {
		return NO;
	} else if  ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return NO;
	} else {
		return YES;
	}
}

- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithType: (NSString *) deviceType andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if([self isEmptyString: sessionID] || [self isEmptyString:deviceType] || [self isEmptyString:UUID]) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Incomplete input parameters"];
		return nil;
	}
	
	NSDictionary *deviceDict =  [NSDictionary dictionaryWithObjectsAndKeys:	deviceType, @"type",
								 UUID,		@"uuid",
								 nil];
	NSDictionary* inputDict = [NSDictionary dictionaryWithObject:deviceDict forKey:@"device"];
	
	NSURL *url               = [NSURL URLWithString:[NSString stringWithFormat: @"%@/%@/%@/%@%@", urlBase, kUrlSensors, csSensorID, kUrlSensorDevice,kUrlJsonSuffix]];
	NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"POST" andSessionID:sessionID andInput:inputDict withError:nil];
	
	NSHTTPURLResponse* httpResponse;
	NSData* responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	if(*error) {
		return NO;
	} else if  ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return NO;
	} else {
		return YES;
	}
}


- (BOOL) postData: (NSArray *) data withSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	return NO;
}

- (NSArray *) getDataForSensor: (NSString *) csSensorID fromDate: (NSDate *) startDate withSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	return nil;
}

#pragma mark Private methods

/** 
 Method for doing an http request to CommonSense.
 
 The request is done synchronously. Resulting data will be transformed from a JSON object into a nested dictionary.
 
 @param urlRequest		The url request to make. Cannot be nil. A valid request can be created with the method createURLRequest provided by this class.
 @param response		An NSHTTPURLResponse object that contains the response information from the server, including the response code and message.
 @param error			The error object that will be filled with more information if there was an error during the call. Will be nil if no error occured.
 @return				Resulting data from the server. Will be nil if the connection to the server failed or there was an error in the call.

 */
- (NSData*) doRequest:(NSURLRequest *) urlRequest andResponse:(NSHTTPURLResponse**)response andError:(NSError **) error
{
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if(! urlRequest) {
		*error = [NSError errorWithDomain:DataStorageEngineErrorDomain code:kCFURLErrorUnknown userInfo:nil];
		*response = nil;
		return nil;
	}
	
	NSData* responseData = [NSURLConnection sendSynchronousRequest:urlRequest
										 returningResponse:response
													 error:error];
	
	//Note that we don't handle errors and response in the request but it is just passed back directly to the caller.
	if (responseData && responseData != (id)[NSNull null]) {
		return responseData;
	} else {
		return nil;
	}
}

/**
 Creates a new NSURLRequest object.
 
 The url request requires a valid url and method. The other fields are optional.
 
 @param url				The complete url of the call. Cannot be nil.
 @param method			Method of the call (eg POST, GET) as string. Cannot be empty.
 @param sessionID		The session ID to use. Can be empty.
 @param input			String with input data to the http request. This will be transformed into a JSON data object. Can be empty.
 @param error			In case of nil return some more info can be found in this object.
 @result				NSURLRequest based on the input parameters
 */
- (NSURLRequest *) createURLRequestTo:(NSURL *)url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andInput:(NSDictionary *)input withError: (NSError * __autoreleasing *) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if((! url) || (! [self isValidHTTPRequestMethod:method])) {
		*error = [self createErrorWithCode:kErrorInvalidInputParameters andMessage:@"Invalid input parameters."];
		return nil;
	}
	
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
															cachePolicy:NSURLRequestReloadIgnoringCacheData
															timeoutInterval:requestTimeoutInterval];
	[urlRequest setHTTPMethod:method];
	
	if (! [self isEmptyString:sessionID]) {
		[urlRequest setValue:sessionID forHTTPHeaderField:@"SESSION-ID"];
	}
	
	if (! [self isEmptyString:appKey]) {
		[urlRequest setValue:appKey forHTTPHeaderField:@"APPLICATION-KEY"];
	}
	
	[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if (input) {
		NSData *body = [NSJSONSerialization dataWithJSONObject:input options:0 error:error];
		
		if(body) {
			[urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
			[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
			[urlRequest setHTTPBody:[body gzippedData]];
		}
	}
	
	return (NSURLRequest *) urlRequest;
}

/**
 Checks whether an HTTP Request method is valid
 
 @param method	A string representation of the method to be used
 @result		Whether or not this is a valid method
*/
- (BOOL) isValidHTTPRequestMethod: (NSString *) method {
	return (method) && ([method isEqualToString:@"GET"]			||
						[method isEqualToString:@"POST"]		||
						[method isEqualToString:@"PUT"]			||
						[method isEqualToString:@"DELETE"]		||
						[method isEqualToString:@"HEAD"]		||
						[method isEqualToString:@"CONNECT"]		||
						[method isEqualToString:@"OPTIONS"]		||
						[method isEqualToString:@"TRACE"]);
}

//Returns whether the stringToTest is nil or an empty string
- (BOOL) isEmptyString:(NSString *)stringToTest {
	return ! stringToTest || [stringToTest isEqualToString:@""];
}

//Creates a new NSError object for the DataStorageEngine domain with a given code and message
- (NSError *) createErrorWithCode: (NSInteger) code andMessage: (NSString *) message {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  message, @"Message",
							  nil];
	
	return [NSError errorWithDomain:DataStorageEngineErrorDomain code:code userInfo:userInfo];

}

//Creates a new NSError object for the DataStorageEngine domain with a given code and message
- (NSError *) createErrorWithCode: (NSInteger) code andResponseData: (NSData *) responseData {
	NSString *message = [NSString stringWithFormat:@"Response with data:\n%@", [[NSString alloc] initWithData: responseData encoding:NSUTF8StringEncoding]];
	return [self createErrorWithCode:code andMessage:message];
}

//Creates a string with json formatting from a dictionary. Returns nil if an error occurs. Error information can be found in the error object.
- (NSString *) jsonstringFromDict: (NSDictionary *) dict withError: (NSError * __autoreleasing *) error {

	NSData *inputJsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:error];
	
	if(*error) {
		return nil;
	} else {
		return [[NSString alloc] initWithData:inputJsonData encoding:NSUTF8StringEncoding];
	}
}

//Make a url with the included action
- (NSURL*) makeCSRestUrlFor:(const NSString *) action append:(NSString *) appendix
{
	if([self isEmptyString:(NSString *)action]) {
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

//Printing function for debugging
- (void) logUrlRequest: (NSURLRequest *) urlRequest {
	NSLog(@"\nRequest headers:\n %@ \nURL: %@\n Method: %@\n Body:\n %@\n",
		  [urlRequest allHTTPHeaderFields],
		  [urlRequest URL],
		  [urlRequest HTTPMethod],
		  [[NSString alloc] initWithData:[urlRequest HTTPBody] encoding:NSUTF8StringEncoding]);
	
}

//Printing function for debugging
- (void) logJsonData: (NSData *) jsonData {
	NSLog(@"JSON Data:\n%@\n",
		  [[NSString alloc] initWithData: jsonData encoding:NSUTF8StringEncoding]);
}
@end
