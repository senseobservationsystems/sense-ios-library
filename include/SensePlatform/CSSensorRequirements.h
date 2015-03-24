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


/**
 Handles requirements. Requirements are a layer on top of settings that help dealing with several incompatible settings. Right now requirements should be used to handle the enabling and disabling of sensors and to set the sample interval and accuracy for a sensor. Whenever two different consumer set different intervals or accuracies, the lowest value is used.
 
 Requirements are organized and stored per consumer. Hence, when setting a requirement one has to provide a unique string that identifies the consumer. This way, it is easy to remove consumer-related requirements later on again. 
 
 Here is some example code for setting requirements, enabling four sensors and setting the sample interval and accuracy:
 
	 NSString* consumerName = @"com.consumer.name";
	 NSArray* commonRequirements = @[
		 @{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_ACCELERATION, kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL:@35},
		 @{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_ACCELEROMETER_BURST, kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL:@30},
		 @{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_NOISE, kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL:@10},
		 @{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_LOCATION, kCSREQUIREMENT_FIELD_SAMPLE_ACCURACY:@10000}
	 ];
	 [[CSSensorRequirements sharedRequirements] setRequirements:commonRequirements byConsumer:consumerName];
 
 */
@interface CSSensorRequirements : NSObject

 ///Get singleton instance
+ (CSSensorRequirements*) sharedRequirements;

/**Helper function to create a requirement for a sensor
 @param sensor The sensor name for the sensor that should be enabled
 */
+ (NSDictionary*) requirementForSensor:(NSString*) sensor;
/** Helper function to create a requirement for a sensor with an interval
 @param sensor The sensor name for the sensor that should be enabled with a certain interval
 @param interval Time interval describing the frequency with which the sensor should poll new data
 */
+ (NSDictionary*) requirementForSensor:(NSString*) sensor withInterval:(NSTimeInterval)interval;

/** Set requirements for a specific consumer. Overwrites previous requirement for the consumer
 @param requirements Array of requirements to set for that consumer. See the example above for an example of the format
 @param consumer Unique identifier for the consumer setting the requirement (e.g. app identifier or library identifier)
 */
- (void) setRequirements:(NSArray*) requirements byConsumer:(NSString*) consumer;

/** Clear the requirements of a consumer
 @param consumer Identifier of the consumer for which the requirements should be cleared.
 */
- (void) clearRequirementsForConsumer:(NSString*) consumer;

/** Whether the requirements are enabled or disabled. They are enabled by default. If disabled, changing a requirement will not affect the settings */
@property (nonatomic) BOOL isEnabled;

@end
