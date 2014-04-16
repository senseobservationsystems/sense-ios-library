//
//  SensorIdKey.m
//  SensePlatform
//
//  Created by Pim Nijdam on 15/04/14.
//
//

#import "CSSensorIdKey.h"

@implementation CSSensorIdKey
- (id) initWithName:(NSString*) name description:(NSString*) description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID {
    self = [super init];
    if (self) {
        self.name = name;
        self.description = description;
        self.deviceType = deviceType;
        self.deviceUUID = deviceUUID;
        if (self.name == nil)
            self.name = @"";
        if (self.description == nil)
            self.description = @"";
        if (self.deviceType == nil)
            self.deviceType = @"";
        if (self.deviceUUID == nil)
            self.deviceUUID = @"";
    }
    return self;
}

- (id) initWithName:(NSString*) name description:(NSString*) description device:(NSDictionary*) device {
    self = [super init];
    if (self) {
        self.name = name;
        self.description = description;
        self.deviceType = [device valueForKey:@"type"];
        self.deviceUUID = [device valueForKey:@"uuid"];

        if (self.name == nil)
            self.name = @"";
        if (self.description == nil)
            self.description = @"";
        if (self.deviceType == nil)
            self.deviceType = @"";
        if (self.deviceUUID == nil)
            self.deviceUUID = @"";
    }
    return self;
}

- (id) copyWithZone:(NSZone*) zone {
    CSSensorIdKey* copy = [[CSSensorIdKey allocWithZone:zone] initWithName:self.name description:self.description deviceType:self.deviceType deviceUUID:self.deviceUUID];
    return copy;
}

- (NSDictionary*) device {
    if (self.deviceUUID == nil || [self.deviceUUID isEqualToString:@""]) {
        return nil;
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:self.deviceType, @"type", self.deviceUUID, @"uuid", nil];
}

- (BOOL) isEqual:(id)otherObject {
    if (![otherObject isKindOfClass:[CSSensorIdKey class]]) {
        return NO;
    }
    CSSensorIdKey* other = (CSSensorIdKey*)otherObject;

    //if both are nil they are also considered equal
    if (!(self.name == other.name || [self.name isEqual:other.name]))
        return NO;
    if (!(self.description == other.description || [self.description isEqual:other.description]))
        return NO;
    if (!(self.deviceType == other.deviceType || [self.deviceType isEqual:other.deviceType]))
        return NO;
    if (!(self.deviceUUID == other.deviceUUID || [self.deviceUUID isEqual:other.deviceUUID]))
        return NO;

    return YES;
}

- (NSUInteger) hash {
    return [self.name hash] ^ [self.description hash] ^ [self.deviceType hash] ^ [self.deviceUUID hash];
}
@end
