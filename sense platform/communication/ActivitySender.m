//
//  ActivitySender.m
//  activityracker
//
//  Created by Pim Nijdam on 2/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "ActivitySender.h"
#import "CSJSON.h"

//Declare private methods
@interface ActivitySender(private)
- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url withMethod:(NSString*)method withHeaderFields:(NSDictionary*) HTTPHeaderFields output:(NSData**)output;
@end

@implementation ActivitySender {
    NSString* accessToken;
}

- (BOOL) isLoggedIn {
    return accessToken != nil;
}

- (BOOL) updateActivityTokenFromToken:(NSString*) token {
    NSString* formattedUrl = [NSString stringWithFormat:@"https://usw1.pulsetracks.com/activities/api/facebookconnect?access_token=%@", token];
    NSURL* url = [[NSURL alloc] initWithString:formattedUrl];
    NSData* data = nil;
    NSHTTPURLResponse* response = [self doRequestTo:url withMethod:@"POST" withHeaderFields:nil output:&data];
    if (response.statusCode >= 200 && response.statusCode < 300 && data != nil) {
        //extract the access token
        //interpret JSON
        NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary* jsonResponse;
        @try {
            jsonResponse = [jsonString JSONValue];
            accessToken = [jsonResponse objectForKey:@"token"];
        }
        @catch (NSException *exception) {
            
        }
    } else
        return NO;
}

- (BOOL) uploadGPX:(NSString*)gpx {
    if (accessToken == nil)
        return NO;
    NSURL* url = [[NSURL alloc] initWithString:@"https://usw1.pulsetracks.com/activities/api/upload"];
    NSDictionary* fields = [NSDictionary dictionaryWithObjectsAndKeys:
                            accessToken, @"access_token",
                            @"Activity Sensor",@"source",
                            gpx, @"gpxdata",
                            nil];
    
    NSHTTPURLResponse* response = [self doRequestTo:url withMethod:@"POST" withHeaderFields:fields output:nil];
    //TODO: it appears that we also need to check wether an error was returned (despite a positive status code)
    return response.statusCode >= 200 && response.statusCode < 300;
}

- (NSHTTPURLResponse*) doRequestTo:(NSURL *)url withMethod:(NSString*)method withHeaderFields:(NSDictionary*) HTTPHeaderFields output:(NSData**)output
{
    NSMutableString* formattedUrl = [NSMutableString stringWithFormat:@"%@", url];
    BOOL first = YES;
    for (NSString* field in HTTPHeaderFields) {
        NSMutableString* value = [HTTPHeaderFields objectForKey:field];
        if (first)
            [formattedUrl appendString:@"?"];
        else
            [formattedUrl appendString:@"&"];
        [formattedUrl appendFormat:@"%@=%@", field, [value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
        first = NO;
    }
    NSLog(@"post: %@", [NSURL URLWithString:formattedUrl]);
    //use percent encoding
 	NSMutableURLRequest* urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:formattedUrl]
															  cachePolicy:NSURLRequestReloadIgnoringCacheData
														  timeoutInterval:30];
	//set method
	[urlRequest setHTTPMethod:method];
    
    [urlRequest setAllHTTPHeaderFields:HTTPHeaderFields];

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
		NSLog(@"Error failure reason: \'%@\'.", [error localizedFailureReason] );
	}
	//log response
	if (response) {
		NSLog(@"%@ \"%@\" responded with status code %d", method, url, [response statusCode]);
	}
	
	if (responseData != nil)
	{
		if (output != nil)
            *output = responseData;
        NSString* jsonString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Returned: %@", jsonString);
	}
	
	return response;
}


@end
