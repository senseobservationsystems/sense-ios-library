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

static const NSString* kUrlBaseURL = @"https://api.sense-os.nl";
static const NSString* kUrlJsonSuffix = @".json";
static const NSString* kUrlData = @"data";
static const NSString* kUrlDevices = @"devices";
static const NSString* kUrlLogin = @"login";
static const NSString* kUrlLogout = @"logout";
static const NSString* kUrlSensorDevice = @"device";
static const NSString* kUrlSensors = @"sensors";
static const NSString* kUrlUsers = @"users";


@implementation CSSender
@synthesize sessionCookie;

static const NSInteger STATUSCODE_UNAUTHORIZED = 403;


- (id) init
{	
    self = [super init];
    if (self)
	{
    }
    return self;
}


#pragma mark -
#pragma mark Public methods

- (BOOL) isLoggedIn {
	return sessionCookie != nil;
}

- (void) setUser:(NSString*)user andPasswordHash:(NSString*) hash {
	if (sessionCookie != nil)
		[self logout];
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

- (BOOL) login
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

	NSURL* url = [self makeUrlFor:@"login"];
	NSData* contents;
	NSHTTPURLResponse* response = [self doRequestTo:url method:@"POST" input:json output:&contents cookie:nil];

	BOOL succeeded = YES;
	//check response code
	if ([response statusCode] != 200)
	{
		NSLog(@"Couldn't login.");
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];		
		NSLog(@"Responded: %@", responded);
		succeeded = NO;
	} else {
		//interpret JSON
		NSDictionary* jsonResponse = [NSJSONSerialization JSONObjectWithData:contents options:0 error:&jsonError];
		self.sessionCookie = [NSString stringWithFormat:@"session_id=%@",[jsonResponse valueForKey:@"session_id"]];
	}
    
	return succeeded;
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

- (NSDictionary*) listSensors {
	return [self doJsonRequestTo:[self makeUrlFor:@"sensors" append:@"?per_page=1000&details=full"] withMethod:@"GET" withInput:nil];
}

- (NSDictionary*) listSensorsForDevice:(NSDictionary*)device {
	//get device
	NSArray* devices = [[self doJsonRequestTo:[self makeUrlFor:@"devices" append:@"?per_page=1000"] withMethod:@"GET" withInput:nil] valueForKey:@"devices"];
	NSInteger deviceId = -1;
	NSLog(@"This device: type: \"%@': uuid: \"%@\"", [device valueForKey:@"type"], [device valueForKey:@"uuid"]);
	for (NSDictionary* remoteDevice in devices) {
		if ([remoteDevice isKindOfClass:[NSDictionary class]]) {
			NSString* uuid = [remoteDevice valueForKey:@"uuid"];
			NSString* type = [remoteDevice valueForKey:@"type"];
			
			if (([type caseInsensitiveCompare:[device valueForKey:@"type"]] == 0) && ([uuid caseInsensitiveCompare:[device valueForKey:@"uuid"]] == 0)) {
				deviceId = [[remoteDevice valueForKey:@"id"] integerValue];
				NSLog(@"Mathed device with id %d", deviceId);
				break;
			}
		}
	}
	
	//if device unknown, then it follows it has no sensors
	if (deviceId == -1) return [NSDictionary dictionaryWithObjectsAndKeys:[NSArray array], @"sensors", nil];

	return [self doJsonRequestTo:[self makeSensorsUrlForDeviceId:deviceId] withMethod:@"GET" withInput:nil];
}

- (NSDictionary*) listConnectedSensorsFor:(NSString*)sensorId {
	return [self doJsonRequestTo:[self makeUrlForConnectedSensors:sensorId] withMethod:@"GET" withInput:nil];
}

- (NSDictionary*) createSensorWithDescription:(NSDictionary*) description {
	NSDictionary* request = [NSDictionary dictionaryWithObject:description forKey:@"sensor"];
    NSData* contents = nil;
	NSHTTPURLResponse* response = [self doJsonRequestTo:[self makeUrlFor:@"sensors"] withMethod:@"POST" withInput:request output:contents];
    NSMutableDictionary* sensorDescription = [description mutableCopy];
    //check response code
	if ([response statusCode] > 200 && [response statusCode] < 300)
	{
        @try {
            NSDictionary* header = response.allHeaderFields;
            NSString* location = [header valueForKey:@"location"];
            NSArray* locationComponents = [location componentsSeparatedByString:@"/"];
            NSString* sensorId = [locationComponents objectAtIndex:[locationComponents count] -1];
            
            [sensorDescription setValue:sensorId forKey:@"id"];
        }
        @catch (NSException *exception) {
            NSLog(@"Exception while creating sensor %@: %@", description, exception);
        }

        return sensorDescription;
	}

	return nil;
}

- (BOOL) connectSensor:(NSString*)sensorId ToDevice:(NSDictionary*) device {
	NSDictionary* request = [NSDictionary dictionaryWithObject:device forKey:@"device"];
	
	[self doJsonRequestTo:[self makeUrlForAddingSensorToDevice:sensorId] withMethod:@"POST" withInput:request];
	return YES;
}

- (BOOL) shareSensor: (NSString*)sensorId WithUser:(NSString*)user {
    //share sensor with username
    NSDictionary* userEntry = [NSDictionary dictionaryWithObject:user forKey:@"id"];
    NSDictionary* request = [NSDictionary dictionaryWithObject:userEntry forKey:@"user"];
	
	[self doJsonRequestTo:[self makeUrlForSharingSensor:sensorId] withMethod:@"POST" withInput:request];
    //TODO: this method should check wether the sharing succeeded
	return YES;
}

- (BOOL) uploadData:(NSArray*) data forSensorId:(NSString*)sensorId {	
	NSDictionary* sensorData = [NSDictionary dictionaryWithObjectsAndKeys:
							  data, @"data", nil];
    //make session
	if (sessionCookie == nil) {
		if (NO == [self login])
			return NO;
        
	}
	NSString* method = @"POST";
    NSURL* url = [self makeUrlForSensor:sensorId];
	NSData* contents;
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sensorData options:0 error:&error];
	NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	NSHTTPURLResponse* response = [self doRequestTo:url method:method input:json output:&contents cookie:sessionCookie];
	
	//handle unauthorized error
	if ([response statusCode] == STATUSCODE_UNAUTHORIZED) {
		//relogin (session might've expired)
		if ([self login]) {
            //redo request
            response = [self doRequestTo:url method:method input:json output:&contents cookie:sessionCookie];
        }
	}
    
	//check response code
	if ([response statusCode] > 200 && [response statusCode] < 300)
	{
        return YES;
	} else {
        //Ai, some error that couldn't be resolved. Log and return error
		NSLog(@"%@ \"%@\" failed with status code %d", method, url, [response statusCode]);
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSLog(@"Responded: %@", responded);
		return NO;
    }
}

- (NSArray*) getDataFromSensor: (NSString*)sensorId nrPoints:(NSInteger) nrPoints {
	return [[self doJsonRequestTo:[self makeUrlForGettingSensorData:sensorId nrPoints:nrPoints order:@"DESC"] withMethod:@"GET" withInput:nil] valueForKey:@"data"];
}
            
- (BOOL) giveFeedbackToStateSensor:(NSString*)sensorId from:(NSDate*) from to:(NSDate*)to label:(NSString*) label {
    @try {
        //weird clutch, need the sensor id of a connected sensor to obtain the service
        //get a connected sensor
        NSDictionary* connectedSensors = [self listConnectedSensorsFor:sensorId];
        
        if ([connectedSensors count] == 0)
            return NO;

        NSString* connectedSensorId = [[[connectedSensors valueForKey:@"sensors"] objectAtIndex:0] valueForKey:@"id"];
        
        if (connectedSensorId == nil)
            return NO;
        
        //prepare request
        NSDictionary* request = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSString stringWithFormat:@"%.3f", [from timeIntervalSince1970]], @"start_date",
                                 [NSString stringWithFormat:@"%.3f", [to timeIntervalSince1970]], @"end_date",
                                 label, @"class_label",
                                 nil];
        NSURL* url = [self makeUrlForServiceMethod:@"manualLearn" sensorId:connectedSensorId stateSensorId:sensorId];
        [self doJsonRequestTo:url withMethod:@"POST" withInput:request];
        return YES;
    }
    @catch (NSException *exception) {
        NSLog(@"Error while giving feedback: %@", exception.description);
    }

    return NO;
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
		NSLog(@"%@ \"%@\" failed with status code %d", method, url, [response statusCode]);
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
		NSLog(@"%@ \"%@\" failed with status code %d", method, url, [response statusCode]);
		NSString* responded = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSLog(@"Responded: %@", responded);
        //TODO: throw clean exception that details the exception
		@throw [NSException exceptionWithName:@"Request failed" reason:nil userInfo:nil];
	}
    
    return response;
}


- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie
{
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:30];
	//set method method
	[urlRequest setHTTPMethod:method];
	
	//Cookie
	if (cookie != nil)
		[urlRequest setValue:cookie forHTTPHeaderField:@"cookie"];
	
	if (input != nil)
	{
		//Talking JSON
		[urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
		const char* bytes = [input UTF8String];
		NSData * body = [NSData dataWithBytes:bytes length: strlen(bytes)];
		[urlRequest setHTTPBody:body];
	}
	
	//connect
	NSHTTPURLResponse* response=nil;
	NSError* error = nil;
	NSData* responseData;
	
	//Synchronous request
	responseData = [NSURLConnection sendSynchronousRequest:urlRequest
										 returningResponse:&response
													 error:&error];
	//don't handle errors in the request, just log them
	if (error != nil) {
		NSLog(@"Error during request \'%@\': %@",	[urlRequest description] ,	error);
		NSLog(@"Error description: \'%@\'.", [error description] );
		NSLog(@"Error userInfo: \'%@\'.", [error userInfo] );
		NSLog(@"Error failure reason: \'%@\'.", [error localizedFailureReason] );
		NSLog(@"Error recovery options reason: \'%@\'.", [error localizedRecoveryOptions] );
		NSLog(@"Error recovery suggestion: \'%@\'.", [error localizedRecoverySuggestion] );
	}
	
	//log response
	if (response) {
		NSLog(@"%@ \"%@\" responded with status code %d", method, url, [response statusCode]);
	}
	
	if (output != nil)
	{
		*output = responseData;
	}
	
	return response;
}

///Creates the url using CommonSense.plist
- (NSURL*) makeUrlFor:(NSString*) action
{
	return [self makeUrlFor:action append:@""];
}

- (NSURL*) makeUrlFor:(NSString*) action append:(NSString*) appendix
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
	NSString* url = [NSString stringWithFormat: @"%@/%@/%d/%@%@%@",
					 kUrlBaseURL,
					 kUrlDevices,
					 deviceId,
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
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@?per_page=%i&sort=%@",
					 kUrlBaseURL,
					 kUrlSensors,
					 sensorId,
 					 kUrlData,
					 kUrlJsonSuffix,
                     nrPoints,
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
@end
