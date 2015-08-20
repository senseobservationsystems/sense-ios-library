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

@implementation DSEHTTPRequestHelper


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




+ (NSURLRequest *) createURLRequestTo:(NSURL *)url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andAppKey: (NSString *) appKey andTimeoutInterval: (NSInteger) requestTimeoutInterval andInput:(NSDictionary *)input withError: (NSError * __autoreleasing *) error {
	
	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestReloadIgnoringCacheData
														   timeoutInterval:requestTimeoutInterval];
	[urlRequest setHTTPMethod:method];
	
	if (! [NSString isEmptyString:sessionID]) {
		[urlRequest setValue:sessionID forHTTPHeaderField:@"SESSION-ID"];
	}
	
	if (! [NSString isEmptyString:appKey]) {
		[urlRequest setValue:appKey forHTTPHeaderField:@"APPLICATION-KEY"];
	}
	
	[urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
	
	if (input) {
		@try {
			NSData *body = [NSJSONSerialization dataWithJSONObject:input options:0 error:error];
            
            //TODO:
            //[NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
            NSString *jsonString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            NSLog(@"### JSON Output: %@", jsonString);

            
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
