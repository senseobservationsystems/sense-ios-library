//
//  CSUploader.h
//  SensePlatform
//
//  Created by Pim Nijdam on 14/04/14.
//
//

#import <Foundation/Foundation.h>
#import "CSStorage.h"
#import "CSSender.h"

@interface CSUploader : NSObject
- (id) initWithStorage:(CSStorage*) theStorage andSender:(CSSender*) theSender;
- (BOOL) upload;
@end
