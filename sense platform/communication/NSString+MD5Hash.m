//
//  NSString+MD5Hash.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NSString+MD5Hash.h"
#import <CommonCrypto/CommonDigest.h>


@implementation NSString (MD5Hash)

+ (NSString *) MD5HashOf:(NSString*)string {	
    const char* bytes = [string UTF8String];
    unsigned char hash[CC_MD5_DIGEST_LENGTH];
	
    CC_MD5(bytes, strlen(bytes), hash);
	
	//represent
    NSMutableString *hashString = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hashString appendFormat:@"%02X", hash[i]];
    return [hashString lowercaseString];
}

- (NSString *) MD5Hash {
	return [NSString MD5HashOf:self];
}
@end
