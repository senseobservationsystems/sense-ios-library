//
//  DSEHTTPRequestHelper.m
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import "DSEHTTPRequestHelper.h"
#import "DSEErrors.h"
#import "NSString+Utils.h"
#import "NSData+GZIP.h"

const int requestTimeoutInterval = 10;			//Time out of 10 sec for every request

@implementation DSEHTTPRequestHelper

+ (NSData*) doRequestTo:(NSURL *) url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andAppKey: (NSString *) appKey andInput:(NSDictionary *)input andResponse:(NSHTTPURLResponse *__autoreleasing *)response andError:(NSError *__autoreleasing *)error {
	
	NSURLRequest *request = [self createURLRequestTo:url withMethod:method andSessionID:sessionID andAppKey:appKey andInput:input withError:error];
	
	if(error && *error) {
		return nil;
	}
	
	return [self doRequest:request andResponse:response andError:error];
	
}

+ (NSData*) doRequest:(NSURLRequest *) urlRequest andResponse:(NSHTTPURLResponse**)response andError:(NSError **) error
{
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




+ (NSURLRequest *) createURLRequestTo:(NSURL *)url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andAppKey: (NSString *) appKey andInput:(NSDictionary *)input withError: (NSError * __autoreleasing *) error {
	
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:requestTimeoutInterval];
	[urlRequest setHTTPMethod:method];
	
	if ([NSString isValidString:sessionID]) {
		[urlRequest setValue:sessionID forHTTPHeaderField:@"SESSION-ID"];
	}
	
	if ([NSString isValidString:appKey]) {
		[urlRequest setValue:appKey forHTTPHeaderField:@"APPLICATION-KEY"];
	}
	
	[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if (input) {
		@try {
			NSData *body = [NSJSONSerialization dataWithJSONObject:input options:0 error:error];
			[urlRequest setValue:@"application/json" forHTTPHeaderField:@"content-type"];
			[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
			[urlRequest setHTTPBody:[body gzippedData]];
		}
		@catch (NSException *exception) {
			NSLog(@"Exception when processing input dictionary:\n %@", exception);
		}
	}
	
	return (NSURLRequest *) urlRequest;
}


+ (BOOL) isValidHTTPRequestMethod: (NSString *) method {
	return (method) && ([method isEqualToString:@"GET"]			||
						[method isEqualToString:@"POST"]		||
						[method isEqualToString:@"PUT"]			||
						[method isEqualToString:@"DELETE"]		||
						[method isEqualToString:@"HEAD"]		||
						[method isEqualToString:@"CONNECT"]		||
						[method isEqualToString:@"OPTIONS"]		||
						[method isEqualToString:@"TRACE"]);
}


+ (BOOL) evaluateResponseWithData: (NSData*) responseData andHttpResponse: (NSHTTPURLResponse *) httpResponse andError: (NSError **) error {

	if(*error) {
		return NO;
	} else if  ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [self createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return NO;
	} else {
		return YES;
	}
}

+ (NSString *) processResponseWithData: (NSData *) responseData andHTTPResponse: (NSHTTPURLResponse *) httpResponse andError: (NSError **) error andBlock: (NSString *(^)()) processBlock {
	
	if (*error) {
		return nil;
	} else if ([httpResponse statusCode] < 200 || [httpResponse statusCode] > 300) {
		*error = [DSEHTTPRequestHelper createErrorWithCode:[httpResponse statusCode] andResponseData:responseData];
		return nil;
	} else {
		return processBlock();
	}
}

+ (NSError *) createErrorWithCode: (NSInteger) code andMessage: (NSString *) message {
	NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							  message, @"Message",
							  nil];
	
	return [NSError errorWithDomain:DataStorageEngineErrorDomain code:code userInfo:userInfo];
	
}


+ (NSError *) createErrorWithCode: (NSInteger) code andResponseData: (NSData *) responseData {
	NSString *message = [NSString stringWithFormat:@"Response with data:\n%@", [[NSString alloc] initWithData: responseData encoding:NSUTF8StringEncoding]];
	return [self createErrorWithCode:code andMessage:message];
}




@end
