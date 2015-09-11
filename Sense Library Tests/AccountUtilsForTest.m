//
//  AccountUtilsForTest.m
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 08/09/15.
//
//

#import "DSEHTTPRequestHelper.h"
#import "NSString+Utils.h"
#import "DSEErrors.h"
#import "NSString+MD5Hash.h"
#import "NSData+GZIP.h"
#import "AccountUtilsForTest.h"


@implementation AccountUtilsForTest {
    
}

#pragma mark User (Public)

+ (NSString *) loginUser: (NSString *) username andPassword: (NSString *) password andError: (NSError **) error {
    
    if( (!error) || ![NSString isValidString:username] || ![NSString isValidString:password]) {
        [NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
    }
    
    NSURL *url               = [self makeUrlFor:kUrlLogin append:nil];
    NSDictionary* inputDict  = @{@"username": username,
                                 @"password": [NSString MD5HashOf:password] };
    
    NSHTTPURLResponse* httpResponse;
    NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:nil andAppKey:testAppKeyStaging andInput:inputDict andResponse:&httpResponse andError:error];
    
    NSString *sessionID = [DSEHTTPRequestHelper processResponseWithData:responseData andHTTPResponse:httpResponse andError:error andBlock: ^{
        NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
        return [NSString stringWithFormat:@"%@",[responseDict valueForKey:@"session_id"]];
    }];
    
    return sessionID;
}


+ (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error {
    
    if( (!error) || ![NSString isValidString:sessionID]) {
        [NSException raise:kExceptionInvalidInput format:@"The input parameters are invalid. Cannot process this request."];
    }
    
    NSURL *url = [self makeUrlFor:kUrlLogout append:nil];
    
    NSHTTPURLResponse* httpResponse;
    NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:sessionID andAppKey:testAppKeyStaging andInput:nil andResponse:&httpResponse andError:error];
    
    return [DSEHTTPRequestHelper evaluateResponseWithData: responseData andHttpResponse: httpResponse andError:error];
}

+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass withEmail:(NSString*) email error:(NSError**) error
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
    NSDictionary* input = [NSDictionary dictionaryWithObjectsAndKeys:
                          userPost, @"user",
                          nil];
    
    NSError *jsonError = nil;
    
    NSURL* url = [self makeUrlFor:@"users"];
    NSHTTPURLResponse* httpResponse;
    NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"POST" andSessionID:nil andAppKey:testAppKeyStaging andInput:input andResponse:&httpResponse andError:error];
    
    BOOL didSucceed = YES;
    //check response code
    if ([httpResponse statusCode] != 201)
    {
        didSucceed = NO;
        NSLog(@"Couldn't register user.");
        NSString* responded = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Responded: %@", responded);
        //interpret json response to set error
        NSError *jsonError = nil;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        NSString* errorString = [NSString stringWithFormat:@"%@", [jsonContents valueForKey:@"error"]];
    }
    return didSucceed;
}

+ (BOOL) deleteUserWithId:(NSString*) userId andSessionID: sessionID error:(NSError**) error
{
    NSString* appendix = [NSString stringWithFormat:@"/%@", userId];
    NSURL* url = [self makeUrlFor:@"users" append: appendix];
    NSHTTPURLResponse* httpResponse;
    NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"DELETE" andSessionID:sessionID andAppKey:testAppKeyStaging andInput:nil andResponse:&httpResponse andError:error];
    //NSHTTPURLResponse* response = [self doRequestTo:url method:@"DELETE" sessionID:sessionID input:nil output:&contents cookie:nil];
    BOOL didSucceed = YES;
    //check response code
    if ([httpResponse statusCode] != 200)
    {
        didSucceed = NO;
        NSLog(@"Couldn't delete user.");
        NSString* responded = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Responded: %@", responded);
        //interpret json response to set error
        NSError *jsonError = nil;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        NSString *errorString = [NSString stringWithFormat:@"%@", [jsonContents valueForKey:@"error"]];
    }
    return didSucceed;
}

+ (NSDictionary*) getCurrentUserWithSessionID:(NSString*) sessionID andError:(NSError**) error
{
    NSURL* url = [self makeUrlFor:@"users" append:@"/current"];
    NSHTTPURLResponse* httpResponse;
    NSData *responseData = [DSEHTTPRequestHelper doRequestTo:url withMethod:@"DELETE" andSessionID:sessionID andAppKey:testAppKeyStaging andInput:nil andResponse:&httpResponse andError:error];
    //NSHTTPURLResponse* response = [self doRequestTo:url method:@"GET" sessionID:sessionID input:nil output:&contents cookie:nil];
    NSDictionary* responseDict;
    
    //check response code
    if ([httpResponse statusCode] != 200)
    {
        NSLog(@"Couldn't get current user info.");
        NSString* responded = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Responded: %@", responded);
        //interpret json response to set error
        NSError *jsonError = nil;
        NSDictionary* jsonContents = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        NSString *error = [NSString stringWithFormat:@"%@", [jsonContents valueForKey:@"error"]];
    } else {
        responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:error];
    }
    return responseDict[@"user"];
}

///Creates the url using CommonSense.plist
+ (NSURL*) makeUrlFor:(const NSString*) action
{
    return [self makeUrlFor:action append:@""];
}


//Make a url with the included action
+ (NSURL*) makeUrlFor:(const NSString *) action append:(NSString *) appendix
{
    if(![NSString isValidString:(NSString *)action]) {
        return nil;
    }
    
    if(! appendix) {
        appendix = @"";
    }
    
    NSString *url;
    
    if([action isEqualToString:(NSString *)kUrlLogin] || [action isEqualToString:(NSString *)kUrlLogout]) {
        url = [NSString stringWithFormat: @"%@/%@%@",
               kUrlAuthenticationStaging,
               action,
               appendix];
    } else {
        url = [NSString stringWithFormat: @"%@/%@%@%@",
               kUrlBaseURLStaging,
               action,
               kUrlJsonSuffix,
               appendix];
    }

    return [NSURL URLWithString:url];
}
@end
