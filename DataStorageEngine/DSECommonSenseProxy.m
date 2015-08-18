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
static const NSString* kUrlAuthenticationLive       = @"https://auth-api.sense-os.nl/v1/login";
static const NSString* kUrlAuthenticationStaging    = @"http://auth-api.staging.sense-os.nl/v1/login";

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
	
	//Check error object. If the user does not pass in a valid error object we create one ourselves
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Note that error is of type NSError * __autoreleasing *, since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	//Check input data
	if(!username || [username isEqualToString:@""] || !password || [password isEqualToString:@""]) {
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Invalid username or password.", @"Message", nil];
		*error = [NSError errorWithDomain:DataStorageEngineErrorDomain code:kErrorCodeInvalidUsernamePassword userInfo:userInfo];
		return nil;
	}
	
	//Prepare input data into a JSON string
	NSDictionary* inputDict = [NSDictionary dictionaryWithObjectsAndKeys:
						  username,							@"username",
						  [NSString MD5HashOf:password],	@"password",
						  nil];
	NSData *inputJsonData = [NSJSONSerialization dataWithJSONObject:inputDict options:0 error:error];
	if(*error) { return nil; }
	NSString *inputString = [[NSString alloc] initWithData:inputJsonData encoding:NSUTF8StringEncoding];
	
	
	//Create url request
	NSURL *url = [NSURL URLWithString:urlAuth];
	NSURLRequest *urlRequest = [self createURLRequestTo:url withMethod:@"POST" andSessionID:nil andInput:inputString];
	
	//Do request
	NSHTTPURLResponse* httpResponse;
	NSData *responseData = [self doRequest:urlRequest andResponse:&httpResponse andError:error];
	
	//Process the result
	if(*error) { return nil; }
	else if (([httpResponse statusCode] != 200) || (!responseData)){
		//Uh oh, an error occured but it was not caught in the error object. Let's create our own.
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys: @"Unknown problem while logging in.", @"Message", nil];
		*error = [NSError errorWithDomain:DataStorageEngineErrorDomain code:[httpResponse statusCode] userInfo:userInfo];
		return nil;
	} else {
		//We have success. Let's grab the returned session ID and be done with it.
		NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
		
		if(*error) {
			return nil;
		} else {
			return [NSString stringWithFormat:@"%@",[responseDict valueForKey:@"session_id"]];
		}
	}
}

- (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	return NO;
}

#pragma mark Sensors and Devices (Public)

- (NSDictionary *) createSensorWithName: (NSString *) name andDisplayName: (NSString *) displayName andDeviceType: (NSString *) deviceType andDataType: (NSString *) dataType andDataStructure: (NSString *) dataStructure andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	return nil;
}

- (NSArray *) getSensorsWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	return nil;
}

- (NSArray *) getDevicesWithSessionID: (NSString *) sessionID andError: (NSError **) error {
	return nil;
}

- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithID: (NSString *) csDeviceID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	return NO;
}

- (BOOL) addSensorWithID: (NSString *) csSensorID toDeviceWithName: (NSString *) csDeviceName andUUID: (NSString *) UUID andSessionID: (NSString *) sessionID andError: (NSError **) error {
	
	return NO;
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

	if(! urlRequest) {
		*error = [NSError errorWithDomain:DataStorageEngineErrorDomain code:kCFURLErrorUnknown userInfo:nil];
		*response = nil;
		return nil;
	}
	
	//Make synchronous request
	NSData* responseData = [NSURLConnection sendSynchronousRequest:urlRequest
										 returningResponse:response
													 error:error];
	
	//Handle the resulting response and potential errors
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
 @result				NSURLRequest based on the input parameters
 */
- (NSURLRequest *) createURLRequestTo:(NSURL *)url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andInput:(NSString *)input {
	
	//Check input parameters and return nil if they are invalid
	if((! url) || (! [self isValidHTTPRequestMethod:method])) {
		return nil;
	}
	
	//Create a mutable url request
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
															cachePolicy:NSURLRequestReloadIgnoringCacheData
															timeoutInterval:requestTimeoutInterval];
	//Set method
	[urlRequest setHTTPMethod:method];
	
	//Set the session ID in the header if it was specified
	if (sessionID && ![sessionID isEqualToString:@""]) {
		[urlRequest setValue:sessionID forHTTPHeaderField:@"cookie"];
	}
	
	//Set the application key in the header if it was specified
	if (appKey && ![appKey isEqualToString:@""]) {
		[urlRequest setValue:appKey forHTTPHeaderField:@"APPLICATION-KEY"];
	}
	
	//Accept compressed response
	[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if (input) {
		//Transform JSON string to compressed bytes
        const char* bytes = [input UTF8String];
        NSData * body     = [NSData dataWithBytes:bytes length: strlen(bytes)];
		[urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
		[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
		[urlRequest setHTTPBody:[body gzippedData]];
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

@end
