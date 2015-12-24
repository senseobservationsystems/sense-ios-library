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

#import "CSSender.h"
#import "NSString+MD5Hash.h"
#import "NSData+GZIP.h"
#import "CSErrorDomain.h"
#import "CSSettings.h"
#import "CSSensorConstants.h"

@import DSESwift;

static NSString* kUrlBaseURL = @"https://api.sense-os.nl";
static NSString* kUrlBaseURLLive = @"https://api.sense-os.nl";
static NSString* kUrlBaseURLStaging = @"http://api.staging.sense-os.nl";
static NSString* kUrlJsonSuffix = @".json";
static NSString* kUrlData = @"data";
static NSString* kUrlDevices = @"devices";
static NSString* kUrlAuthentication= @"https://auth-api.sense-os.nl/v1/login";
static NSString* kUrlAuthenticationLive= @"https://auth-api.sense-os.nl/v1/login";
static NSString* kUrlAuthenticationStaging= @"http://auth-api.staging.sense-os.nl/v1/login";

static NSString* kUrlLogout = @"logout";
static NSString* kUrlSensorDevice = @"device";
static NSString* kUrlSensors = @"sensors";
static NSString* kUrlUsers = @"users";
static NSString* kUrlUploadMultipleSensors = @"sensors/data";


@implementation CSSender
@synthesize sessionCookie;

static const NSInteger STATUSCODE_UNAUTHORIZED = 403;


- (id) init
{	
    self = [super init];
    if (self)
	{
        if([[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUseStaging] isEqualToString:kCSSettingYES]) {
            [self setupForStaging];
        } else {
            [self setupForLive];
        };
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeGeneral] object:nil];

    }
    return self;
}

#pragma mark -
#pragma mark Public methods

- (BOOL) isLoggedIn {
	return sessionCookie != nil;
}

- (void) setUser:(NSString*)user andPasswordHash:(NSString*) hash {
    if (! [self isLoggedIn]){
		[self logout];
    }
	username = user;
	passwordHash = hash;
}

- (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass withEmail:(NSString*) email error:(NSString**) error
{
	//prepare post
	NSMutableDictionary* userPost = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						  user, @"username",
						  [pass MD5Hash], @"password",
						  nil];
    if (email)
        [userPost setValue:email forKey:@"email"];
    else
        [userPost setValue:user forKey:@"email"];
	//encapsulate in "user"
	NSDictionary* post = [NSDictionary dictionaryWithObjectsAndKeys:
						  userPost, @"user",
						  nil];
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:&jsonError];
	NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	
	NSURL* url = [self makeUrlFor:@"users"];
	NSData* contents;
	NSHTTPURLResponse* response = [self doRequestTo:url method:@"POST" input:json output:&contents cookie:nil];
	BOOL didSucceed = YES;
	//check response code
	if ([response statusCode] != 201)
	{
		didSucceed = NO;
		NSLog(@"Couldn't register user.");
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSLog(@"Responded: %@", responded);
		//interpret json response to set error
        NSError *jsonError = nil;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&jsonError];
   		*error = [NSString stringWithFormat:@"%@", [jsonContents valueForKey:@"error"]];
	}
	return didSucceed;
}

- (BOOL) login {
    NSError* error;
    return [self loginWithError:&error];
}

- (BOOL) loginWithError:(NSError **) error
{
	//invalidate current session
	if (sessionCookie != nil)
		[self logout];

	//prepare post
	NSDictionary* post = [NSDictionary dictionaryWithObjectsAndKeys:
						  username, @"username",
						  passwordHash, @"password",
						  nil];

    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:&jsonError];
	NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSURL* url = [NSURL URLWithString:kUrlAuthentication];
	NSData* contents;

    NSError *httpError; // handle network related error
    NSHTTPURLResponse* response = [self doRequestTo:url method:@"POST" input:json output:&contents cookie:nil error:&httpError];

	BOOL succeeded = YES;
	//check response code
    
    if (contents == nil) { // could make the request (possibly network problem)
        *error = httpError;
        succeeded = NO;
    } else if ([response statusCode] != 200) {
		NSLog(@"Couldn't login.");
		NSString* responseBody = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
        
        // try to parse json
        NSError* jsonError = nil;
        NSDictionary* jsonData = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&jsonError];
        
        NSString* errorMsg;
        
        if (jsonError != nil) { // response is not json return the content
            errorMsg = responseBody;
        } else {
            errorMsg = [jsonData objectForKey:@"error"];
        }
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Failure loging in", nil), @"message": errorMsg};

        *error = [NSError errorWithDomain:SensePlatformErrorDomain code:[response statusCode] userInfo:userInfo];
        
        
		succeeded = NO;
	} else {
		//interpret JSON
		NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&jsonError];
        
		self.sessionCookie = [NSString stringWithFormat:@"session_id=%@",[jsonResponse valueForKey:@"session_id"]];
	}
    
	return succeeded;
}

- (NSString*) getUserId{
    return [[[self doJsonRequestTo:[self makeUrlFor:@"users/current"] withMethod:@"GET" withInput:nil] valueForKey:@"user"] valueForKey:@"id"];
}

- (NSString*) getSessionId{
    if (sessionCookie!=nil){
        NSArray* sessionCookieArray = [self.sessionCookie componentsSeparatedByString: @"="];
        return [sessionCookieArray objectAtIndex: 1];
    }else{
        return nil;
    }
}

- (BOOL) logout
{
	if (sessionCookie == nil)
		return FALSE;
	
	//perform request
	NSURL* url = [self makeUrlFor:@"logout"];
	NSHTTPURLResponse* response = [self doRequestTo:url method:@"GET" input:nil output:nil cookie:self.sessionCookie];

	//invalidate session id
	self.sessionCookie = nil;
	//return whether the logout was acknowledged
	return [response statusCode] == 200;
}



#pragma mark -
#pragma mark Private methods

- (NSDictionary*) doJsonRequestTo:(NSURL*) url withMethod:(NSString*)method withInput:(NSDictionary*) input
{
	//make session
	if (sessionCookie == nil) {
		if (![self login])
			return nil;
	}
	
	NSData* contents;
    NSError *error = nil;
    NSString* jsonInput;
    if (input != nil) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:input options:0 error:&error];
        jsonInput = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
	NSHTTPURLResponse* response = [self doRequestTo:url method:method input:jsonInput output:&contents cookie:sessionCookie];
	
	//handle unauthorized error
	if ([response statusCode] == STATUSCODE_UNAUTHORIZED) {
		//relogin (session might've expired)
		[self login];
		//redo request
		response = [self doRequestTo:url method:method input:jsonInput output:&contents cookie:sessionCookie];
	}

	//check response code
	if ([response statusCode] < 200 || [response statusCode] >= 300)
	{
		//Ai, some error that couldn't be resolved. Log and throw exception
		NSLog(@"%@ \"%@\" failed with status code %ld", method, url, (long)[response statusCode]);
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSLog(@"Responded: %@", responded);
        //TODO: throw clean exception that details the exception
		@throw [NSException exceptionWithName:@"Request failed" reason:nil userInfo:nil];
	}

    if (contents && contents.length > 0) {
        //interpret JSON
        NSDictionary* jsonResponse = nil;
        NSError *error = nil;
        jsonResponse = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&error];

        return jsonResponse;
    } else {
        return nil;
    }
}


- (NSHTTPURLResponse*) doJsonRequestTo:(NSURL*) url withMethod:(NSString*)method withInput:(NSDictionary*) input output:(NSData*)contents
{
	//make session
	if (sessionCookie == nil) {
		if (![self login])
			return nil;
	}
	
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:input options:0 error:&error];
	NSString *jsonInput = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	NSHTTPURLResponse* response = [self doRequestTo:url method:method input:jsonInput output:&contents cookie:sessionCookie];
	
	//handle unauthorized error
	if ([response statusCode] == STATUSCODE_UNAUTHORIZED) {
		//relogin (session might've expired)
		[self login];
		//redo request
		response = [self doRequestTo:url method:method input:jsonInput output:&contents cookie:sessionCookie];
	}
    
	//check response code
	if ([response statusCode] < 200 || [response statusCode] > 300)
	{
		//Ai, some error that couldn't be resolved. Log and throw exception
		NSLog(@"%@ \"%@\" failed with status code %ld", method, url, (long)[response statusCode]);
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSLog(@"Responded: %@", responded);
        //TODO: throw clean exception that details the exception
		@throw [NSException exceptionWithName:@"Request failed" reason:nil userInfo:nil];
	}
    
    return response;
}

- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie {
    NSError* error;
    return [self doRequestTo:url method:method input:input output:output cookie:cookie error:&error];
}

- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie error:(NSError **) error
{
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:30];
	//set method method
	[urlRequest setHTTPMethod:method];
	
	//Cookie
	if (cookie != nil)
		[urlRequest setValue:cookie forHTTPHeaderField:@"cookie"];
    if (self.applicationKey != nil)
        [urlRequest setValue:self.applicationKey forHTTPHeaderField:@"APPLICATION-KEY"];
    //Accept compressed response
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if (input != nil)
	{
		//Talking JSON
		[urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
		const char* bytes = [input UTF8String];
		NSData * body = [NSData dataWithBytes:bytes length: strlen(bytes)];
        //compress the body
        [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
		[urlRequest setHTTPBody:[body gzippedData]];
		//[urlRequest setHTTPBody:body];
	}
	
	//connect
	NSHTTPURLResponse* response=nil;
	NSData* responseData;
	
	//Synchronous request
	responseData = [NSURLConnection sendSynchronousRequest:urlRequest
										 returningResponse:&response
													 error:error];
    
	//don't handle errors in the request, just log them
	if (*error != nil) {
		NSLog(@"Error during request \'%@\': %@",	[urlRequest description] ,	*error);
		NSLog(@"Error description: \'%@\'.", [*error description] );
		NSLog(@"Error userInfo: \'%@\'.", [*error userInfo] );
		NSLog(@"Error failure reason: \'%@\'.", [*error localizedFailureReason] );
		NSLog(@"Error recovery options reason: \'%@\'.", [*error localizedRecoveryOptions] );
		NSLog(@"Error recovery suggestion: \'%@\'.", [*error localizedRecoverySuggestion] );
	}
	
	//log response
    if (response) {
        NSLog(@"%@ \"%@\" responded with status code %ld", method, url, (long)[response statusCode]);
        if (response.statusCode < 200 || response.statusCode >= 300) {
            NSLog(@"Sent: %@", input);
            NSLog(@"Received: %@", [[NSString alloc] initWithBytes:responseData.bytes length:responseData.length encoding:NSUTF8StringEncoding]);
        }
	}
	
	if (output != nil)
	{
		*output = responseData;
	}
	
	return response;
}

#pragma mark - Urls

///Creates the url using CommonSense.plist
- (NSURL*) makeUrlFor:(const NSString*) action
{
	return [self makeUrlFor:action append:@""];
}

- (NSURL*) makeUrlFor:(const NSString*) action append:(NSString*) appendix
{
	NSString* url = [NSString stringWithFormat: @"%@/%@%@%@",
					 kUrlBaseURL,
					 action,
					 kUrlJsonSuffix,
                     appendix];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForSensor:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 kUrlData,
					 kUrlJsonSuffix];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeSensorsUrlForDeviceId:(NSInteger)deviceId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%ld/%@%@%@",
					 kUrlBaseURL,
					 kUrlDevices,
					 (long)deviceId,
 					 kUrlSensors,
					 kUrlJsonSuffix,
                     @"?per_page=1000"];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForAddingSensorToDevice:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 kUrlSensorDevice,
					 kUrlJsonSuffix];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForSharingSensor:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 kUrlUsers,
					 kUrlJsonSuffix];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForGettingSensorData:(NSString*) sensorId nrPoints:(NSInteger) nrPoints order:(NSString*) order {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@?per_page=%li&sort=%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 kUrlData,
					 kUrlJsonSuffix,
                     (long)nrPoints,
                     order];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForServiceMethod:(NSString*) method sensorId:(NSString*) sensorId stateSensorId:(NSString*) stateSensorId {
    //example: http://api.sense-os.nl/sensors/1/services/1/method_name.json
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@/%@/%@%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 @"services",
                     stateSensorId,
					 method,
                     kUrlJsonSuffix];
	
	return [NSURL URLWithString:url];
}
- (NSURL*) makeUrlForConnectedSensors:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@?per_page=1000",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 @"sensors",
					 kUrlJsonSuffix];
	
	return [NSURL URLWithString:url];
}


- (void) generalSettingChanged: (NSNotification*) notification {
    if ([notification.object isKindOfClass:[CSSetting class]]) {
        CSSetting* setting = notification.object;
        if ([setting.name isEqualToString:kCSGeneralSettingUseStaging]) {
            if(setting.value) { [self setupForStaging];} else { [self setupForLive];};
        }
      }
}

- (void) setupForStaging {
    kUrlAuthentication = kUrlAuthenticationStaging;
    kUrlBaseURL = kUrlBaseURLStaging;
}

- (void) setupForLive {
    kUrlAuthentication = kUrlAuthenticationLive;
    kUrlBaseURL = kUrlBaseURLLive;
}


@end
