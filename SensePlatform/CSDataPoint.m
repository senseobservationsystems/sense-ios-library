//
//  CSDataPoint.m
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import "CSDataPoint.h"
@import DSESwift;

@implementation CSDataPoint
- (NSDictionary*) device {
    return [NSDictionary dictionaryWithObjectsAndKeys:self.deviceType, @"type",
                          self.deviceUUID, @"uuid",
                          nil];
}

- (NSDictionary*) timeValueDict {
    return [NSJSONSerialization JSONObjectWithData:[self.timeValue dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}
@end
