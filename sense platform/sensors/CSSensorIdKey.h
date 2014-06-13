//
//  SensorIdKey.h
//  SensePlatform
//
//  Created by Pim Nijdam on 15/04/14.
//
//

#import <Foundation/Foundation.h>

@interface CSSensorIdKey : NSObject<NSCopying>
@property NSString* name;
@property NSString* description;
@property NSString* deviceType;
@property NSString* deviceUUID;

- (id) initWithName:(NSString*) name description:(NSString*) description deviceType:(NSString*) deviceType deviceUUID:(NSString*) deviceUUID;
- (id) initWithName:(NSString*) name description:(NSString*) description device:(NSDictionary*) device;
- (NSDictionary*) device;
@end


