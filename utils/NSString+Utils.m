//
//  NSString+Utils.m
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

+ (BOOL) isEmptyString:(NSString *)string {
	if([string length] == 0) { //string is empty or nil
		return YES;
	}
	
	if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
		//string is all whitespace
		return YES;
	}
	
	return NO;
}


+ (NSString *) jsonstringFromDict: (NSDictionary *) dict withError: (NSError * __autoreleasing *) error {
	
	if(! error) {
		NSError * __autoreleasing errorPointer;
		error = &errorPointer; //Since arc does not allow __autoreleasing casts we have to do it this way.
	}
	
	if(! dict) {
		return nil;
	}
		
	NSData *inputJsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:error];
	
	if(*error) {
		return nil;
	} else {
		return [[NSString alloc] initWithData:inputJsonData encoding:NSUTF8StringEncoding];
	}
}

+ (NSString *) jsonstringFromData: (NSData *) jsonData {
	
	if(! jsonData) {
		return nil;
	}

	return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
