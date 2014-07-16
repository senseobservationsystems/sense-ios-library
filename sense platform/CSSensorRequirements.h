//
//  CSSensorRequirements.h
//  SensePlatform
//
//  Created by Pim Nijdam on 4/15/13.
//
//

#import <Foundation/Foundation.h>

@interface CSSensorRequirements : NSObject
- (void) setRequirements:(NSArray*) requirements byConsumer:(id) consumer;
- (void) clearRequirementsForConsumer:(id) consumer;

@end
