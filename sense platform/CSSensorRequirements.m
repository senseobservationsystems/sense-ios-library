//
//  CSSensorRequirements.m
//  SensePlatform
//
//  Created by Pim Nijdam on 4/15/13.
//
//

#import "CSSensorRequirements.h"

@implementation CSSensorRequirements {
    NSMutableDictionary* requirements;
}

- (id) init {
    self = [super init];
    if (self) {
        requirements = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) setIntervalRequirement:(NSInteger) interval forSensor:(NSString*) sensor byConsumer:(id) consumer {
    //TODO: update requirements and calculate them
}

@end
