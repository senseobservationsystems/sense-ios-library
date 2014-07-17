//
//  CSSensorRequirements.h
//  SensePlatform
//
//  Created by Pim Nijdam on 4/15/13.
//
//

#import <Foundation/Foundation.h>

extern NSString* const kCSREQUIREMENT_FIELD_OPTIONAL;
extern NSString* const kCSREQUIREMENT_FIELD_SENSOR_NAME;
extern NSString* const kCSREQUIREMENT_FIELD_REASON;
extern NSString* const kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL;
extern NSString* const kCSREQUIREMENT_FIELD_SAMPLE_ACCURACY;
extern NSString* const kCSREQUIREMENT_FIELD_AT_TIME;

@interface CSSensorRequirements : NSObject
///Get singleton instance
+ (CSSensorRequirements*) sharedRequirements;

///Helper function to create a requirement for a sensor
+ (NSDictionary*) requirementForSensor:(NSString*) sensor;
///Helper function to create a requirement for a sensor with an interval
+ (NSDictionary*) requirementForSensor:(NSString*) sensor withInterval:(NSTimeInterval)interval;
///Set requirements for a specific consumer. Overwrites previous requirement for the consumer
- (void) setRequirements:(NSArray*) requirements byConsumer:(NSString*) consumer;
///Clear the requirements of a consumer
- (void) clearRequirementsForConsumer:(NSString*) consumer;

@property (nonatomic) BOOL isEnabled;

@end
