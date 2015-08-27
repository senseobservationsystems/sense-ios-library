//
//  DSEHTTPRequestHelper.h
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import <Foundation/Foundation.h>

@interface DSEHTTPRequestHelper : NSObject

/** 
 Method for doing an http request to CommonSense.
 
 The request is done synchronously.
 
 @param url						The complete url of the call. Cannot be nil.
 @param method					Method of the call (eg POST, GET) as string. Cannot be empty.
 @param sessionID				The session ID to use. Can be empty.
 @param appKey					The app key to use. Cannot be empty.
 @param requestTimeoutInterval	The timeout in seconds to specify for this request
 @param input					String with input data to the http request. This will be transformed into a JSON data object. Can be empty.
 @param response		An NSHTTPURLResponse object that contains the response information from the server, including the response code and message.
 @param error			The error object that will be filled with more information if there was an error during the call. Will be nil if no error occured.
 @return				Resulting data from the server. Will be nil if the connection to the server failed or there was an error in the call.
*/
+ (NSData*) doRequestTo:(NSURL *) url withMethod:(NSString*)method andSessionID:(NSString*) sessionID andAppKey: (NSString *) appKey andInput:(NSDictionary *)input andResponse:(NSHTTPURLResponse *__autoreleasing *)response andError:(NSError *__autoreleasing *)error;


/**
 Checks whether an HTTP Request method is valid
 
 @param method	A string representation of the method to be used
 @result		Whether or not this is a valid method
 */
+ (BOOL) isValidHTTPRequestMethod: (NSString *) method;



/**
 Simple evaluation of the response from a server.
 
 Can be used in case no sophisticated analysis of the data is needed. It evaluates any errors and the HTTP response code. If no problems are found it return YES. If errors are found NO is returned and the error object is populated with information about the error.
 
 @param responseData	Data object with the resulting data from the server. Will be used for reporting in the error object. Has to be serializable into a UTF8 string.
 @param httpResponse	Object with the details about the HTTP Response. Will be used to check the statuscode of the response.
 @param error			Will be populated with information in case of an error.
 @result				Whether or not the response was succesfull (i.e., between 200 and 300 statuscode)
 */
+ (BOOL) evaluateResponseWithData: (NSData*) responseData andHttpResponse: (NSHTTPURLResponse *) httpResponse andError: (NSError **) error;

/**
 Processing of the response from a server.
 
 Can be used to check the response from the server, and if successful, process the result using a specified processing block. It evaluates any errors and the HTTP response code.
 
 @param responseData	Data object with the resulting data from the server. Will be used for reporting in the error object. Has to be serializable into a UTF8 string.
 @param httpResponse	Object with the details about the HTTP Response. Will be used to check the statuscode of the response.
 @param error			Will be populated with information in case of an error.
 @param processBlock	A block of code that has to return a string and processes the response data into something that might be of later use.
 @result				String returned by process block. Can be an empty string. Since processBlock cannot return nil, the result will never be nil
 */
+ (NSString *) processResponseWithData: (NSData *) responseData andHTTPResponse: (NSHTTPURLResponse *) httpResponse andError: (NSError **) error andBlock: (NSString *(^)()) processBlock;

/**
 Creates a new NSError object for the DataStorageEngine domain with a given code and message
 
 @param code	Statuscode for the error.
 @param message	Message to put in the error
 @result error	NSError object with the code, message, and DataStorageEngine errordomain
 */
+ (NSError *) createErrorWithCode: (NSInteger) code andMessage: (NSString *) message;


/**
 Creates a new NSError object for the DataStorageEngine domain with a given code and response data
 
 @param code			Statuscode for the error.
 @param responseData	Data will be used to populate the error message
 @result error			NSError object with the code, message, and DataStorageEngine errordomain
 */
+ (NSError *) createErrorWithCode: (NSInteger) code andResponseData: (NSData *) responseData;

@end
