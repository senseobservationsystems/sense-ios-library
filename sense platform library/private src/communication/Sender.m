//
//  Sender.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Sender.h"
#import "NSString+MD5Hash.h"

//Declare private methods using empty category
@interface Sender()
- (NSDictionary*) doJsonRequestTo:(NSURL*) url withMethod:(NSString*)method withInput:(NSDictionary*) input;
- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url method:(NSString*)method input:(NSString*)input output:(NSData**)output cookie:(NSString*) cookie;
- (NSURL*) makeUrlFor:(NSString*) action;
- (NSURL*) makeUrlForSensor:(NSString*) sensorId;
- (NSURL*) makeUrlForAddingSensorToDevice:(NSString*) sensorId;
- (NSURL*) makeSensorsUrlForDeviceId:(NSInteger)deviceId;
- (NSURL*) makeUrlForSharingSensor:(NSString*) sensorId;
@end

@implementation Sender
@synthesize urls;
@synthesize sessionCookie;

static const NSInteger STATUSCODE_UNAUTHORIZED;


- (id) init
{	
    self = [super init];
    if (self)
	{
		//initialise urls from plist
        NSString* errorDesc = nil;
        NSPropertyListFormat format;
        NSString* plistPath;
        plistPath = [[NSBundle mainBundle] pathForResource:@"CommonSense" ofType:@"plist"];
        
        NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
        NSDictionary* temp = (NSDictionary *)[NSPropertyListSerialization
											  propertyListFromData:plistXML
											  mutabilityOption:NSPropertyListImmutable
											  format:&format
											  errorDescription:&errorDesc];
        if (!temp) {
            NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
        }
		
		self.urls = temp;
		
		//initialise nils
		self.sessionCookie = nil;
    }
    return self;
}


#pragma mark -
#pragma mark Public methods

- (BOOL) isLoggedIn {
	return sessionCookie != nil;
}

- (void) setUser:(NSString*)user andPassword:(NSString*) password {
	if (sessionCookie != nil)
		[self logout];
	username = user;
	passwordHash = [password MD5Hash];
}

- (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass error:(NSString**) error
{
	//prepare post
	NSDictionary* userPost = [NSDictionary dictionaryWithObjectsAndKeys:
						  user, @"username",
						  [pass MD5Hash], @"password",
						  user, @"email",
						  nil];
	//encapsulate in "user"
	NSDictionary* post = [NSDictionary dictionaryWithObjectsAndKeys:
						  userPost, @"user",
						  nil];
	
	NSString* json = [post JSONRepresentation];
	
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
		*error = [[responded JSONValue] valueForKey:@"error"];
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

	NSString* json = [post JSONRepresentation];;

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
		NSString* jsonString = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
		NSDictionary* jsonResponse = [jsonString JSONValue];
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
	return [self doJsonRequestTo:[self makeUrlFor:@"sensors"] withMethod:@"GET" withInput:nil];
}

- (NSDictionary*) listSensorsForDevice:(NSDictionary*)device {
	//get device
	NSArray* devices = [[self doJsonRequestTo:[self makeUrlFor:@"devices"] withMethod:@"GET" withInput:nil] valueForKey:@"devices"];
	NSInteger deviceId = -1;
	NSLog(@"This device: type: \"%@': uuid: \"%@\"", [device valueForKey:@"type"], [device valueForKey:@"uuid"]);
	for (NSDictionary* remoteDevice in devices) {
		if ([remoteDevice isKindOfClass:[NSDictionary class]]) {
			NSString* uuid = [remoteDevice valueForKey:@"uuid"];
			NSString* type = [remoteDevice valueForKey:@"type"];
			
			NSLog(@"found type: \"%@\" uuid: \"%@\"", type, uuid);
			if (([type caseInsensitiveCompare:[device valueForKey:@"type"]] == 0) && ([uuid caseInsensitiveCompare:[device valueForKey:@"uuid"]] == 0)) {
				deviceId = [[remoteDevice valueForKey:@"id"] integerValue];
				NSLog(@"Mathed device with id %d", deviceId);
				break;
			}
		}
	}
	
	//if device unknown, then it follows it has no sensors
	if (deviceId == -1) return nil;

	return [self doJsonRequestTo:[self makeSensorsUrlForDeviceId:deviceId] withMethod:@"GET" withInput:nil];
}

- (NSDictionary*) createSensorWithDescription:(NSDictionary*) description {	
	NSDictionary* request = [NSDictionary dictionaryWithObject:description forKey:@"sensor"];
	NSDictionary* response = [self doJsonRequestTo:[self makeUrlFor:@"sensors"] withMethod:@"POST" withInput:request];
	
	return [response valueForKey:@"sensor"];
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
    NSLog(@"%@", [request JSONRepresentation]);
	
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
    NSString* jsonData = [sensorData JSONRepresentation];
	NSHTTPURLResponse* response = [self doRequestTo:url method:method input:jsonData output:&contents cookie:sessionCookie];
	
	//handle unauthorized error
	if ([response statusCode] == STATUSCODE_UNAUTHORIZED) {
		//relogin (session might've expired)
		if ([self login]) {
            //redo request
            response = [self doRequestTo:url method:method input:jsonData output:&contents cookie:sessionCookie];
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
	NSHTTPURLResponse* response = [self doRequestTo:url method:method input:[input JSONRepresentation] output:&contents cookie:sessionCookie];
	
	//handle unauthorized error
	if ([response statusCode] == STATUSCODE_UNAUTHORIZED) {
		//relogin (session might've expired)
		[self login];
		//redo request
		response = [self doRequestTo:url method:method input:[input JSONRepresentation] output:&contents cookie:sessionCookie];
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

    if (contents) {
        //interpret JSON
        NSString* jsonString = [[NSString alloc] initWithData:contents encoding:NSUTF8StringEncoding];
        NSDictionary* jsonResponse = nil;
        @try {
            jsonResponse = [jsonString JSONValue];
        }
        @catch (NSException *exception) {
            
        }
        @finally {
            
        }
        return jsonResponse;
    } else {
        return nil;
    }
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
	NSString* url = [NSString stringWithFormat: @"%@/%@%@",
					 [urls valueForKey:@"baseUrl"],
					 [urls valueForKey:action],
					 [urls valueForKey:@"jsonSuffix"]];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForSensor:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 [urls valueForKey:@"baseUrl"],
					 [urls valueForKey:@"sensors"],
					 sensorId,
 					 [urls valueForKey:@"data"],
					 [urls valueForKey:@"jsonSuffix"]];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeSensorsUrlForDeviceId:(NSInteger)deviceId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%d/%@%@",
					 [urls valueForKey:@"baseUrl"],
					 [urls valueForKey:@"devices"],
					 deviceId,
 					 [urls valueForKey:@"sensors"],
					 [urls valueForKey:@"jsonSuffix"]];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForAddingSensorToDevice:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 [urls valueForKey:@"baseUrl"],
					 [urls valueForKey:@"sensors"],
					 sensorId,
 					 [urls valueForKey:@"sensorDevice"],
					 [urls valueForKey:@"jsonSuffix"]];
	
	return [NSURL URLWithString:url];
}

- (NSURL*) makeUrlForSharingSensor:(NSString*) sensorId {
	NSString* url = [NSString stringWithFormat: @"%@/%@/%@/%@%@",
					 [urls valueForKey:@"baseUrl"],
					 [urls valueForKey:@"sensors"],
					 sensorId,
 					 [urls valueForKey:@"users"],
					 [urls valueForKey:@"jsonSuffix"]];
	
	return [NSURL URLWithString:url];
}
@end
