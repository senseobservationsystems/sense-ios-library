//  sense_platform_library.h
//
//  Created by Pim Nijdam on 4/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

//Include all sensors
#include "CSSensor.h"
#include "CSSensorIds.h"

extern NSString * const kCSDATA_TYPE_JSON;
extern NSString * const kCSDATA_TYPE_INTEGER;
extern NSString * const kCSDATA_TYPE_FLOAT;
extern NSString * const kCSDATA_TYPE_STRING;

extern NSString* const kCSNewSensorDataNotification;

typedef enum {BPM_SUCCES=0, BPM_CONNECTOR_NOT_PRESENT, BPM_NOT_FOUND, BPM_UNAUTHORIZED, BPM_OTHER_ERROR} BpmResult;
typedef void(^bpmCallBack)(BpmResult result, NSInteger newOkMeasurements, NSInteger newFailedMeasurements, NSDate* latestMeasurement);

/**
 * This is the high-level interface for the sense platform.
 */
@interface CSSensePlatform : NSObject
/// Initializes the sense platform.
+ (void) initialize;
/// Returns a list of available sensors of the device
+ (NSArray*) availableSensors;
/// To be called upon termination of the app, allows the platform to flush it's caches to Common Sense
+ (void) willTerminate;
/// Flush data to Common Sense
+ (void) flushData;
/// Flush data to Common Sense, return after the flush is completed
+ (void) flushDataAndBlock;
/// Set the credentials to log in on Common Sense
+ (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password;
/** Register a user in Common Sense
 * @returns Wether the registration succeeded
 */
+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) password;
/// Setup the platform for use with iVitality
+ (void) applyIVitalitySettings;
/** Add a data point for a sensor, if the sensor doesn't exist it will be created
 */
+ (void) addDataPointForSensor:(NSString*) sensorName displayName:(NSString*)displayName deviceType:(NSString*)deviceType dataType:(NSString*)dataType value:(NSString*)value timestamp:(NSDate*)timestamp;
/// This function isn't operational.
+ (void) synchronizeWithBloodPressureMonitor:(bpmCallBack) callback;
/** Retrieve a number of values of a sensor from Common Sense. returns nrLastPoints of the latest values.
 * @param name The name of the sensor to get data from
 * @param onlyFromDevice Wether or not to only look through sensors that are part of this device. Searches all sensors, including those of this device, if set to NO
 * @param nrLastPoints Number of points to retrieve, this function always returns the latest values for the sensor.
 * @returns an array of values, each value is a dictionary that describes the data point
 */
+ (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints;
/** Give feedback on a state sensor.
 * @param state The state to give feedback on.
 * @param from The start date for the feedback.
 * @param to The end date for the feedback.
 * @param label The label of the Feedback, e.g. 'Sit'
 */
+ (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label;
@end