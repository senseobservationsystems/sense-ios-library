//
//  NSString+Utils.h
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Utils)

/**
 Checks whether the string is not nil and has at least one non-whitespace character. 
 
 @param string	The string to check
 @result		If the string has zero length or only whitespace characters
 */
+ (BOOL)isValidString:(NSString *)string;


/**
 Creates a string with json formatting from a dictionary.
 
 @param	dict		The dictionary to transform into a json formatted string
 @param error		An error reference object that will be filled with information in case an error occurs
 @return			Returns nil if an error occurs. Error information can be found in the error object.
 */
+ (NSString *) jsonstringFromDict: (NSDictionary *) dict withError: (NSError * __autoreleasing *) error;


/**
 Creates a string from json data
 
 @param jsonData	Data with UTF-8 enconding that can be transformed into a string
 @return			A string represenation of jsonData
 */

+ (NSString *) jsonstringFromData: (NSData *) jsonData;

@end
