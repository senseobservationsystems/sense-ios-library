#import <Foundation/Foundation.h>


@interface NSString (CSMD5Hash)

-(NSString*) MD5Hash;
+(NSString*) MD5HashOf:(NSString*) string;
@end
