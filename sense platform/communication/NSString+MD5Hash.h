//
//  NSString+MD5Hash.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/14/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (MD5Hash)

-(NSString*) MD5Hash;
+(NSString*) MD5HashOf:(NSString*) string;
@end
