//
//  CSLocationSensor.h
//  SensePlatform
//
//  Created by Joris Janssen on 26/02/15.
//
//

#import "CSSensor.h"
#import <CoreLocation/CoreLocation.h>

/**
 * Sensor for storing location updates
 */
@interface CSLocationSensor : CSSensor {
}

/**
 * Store a new location point in the location sensor. If the sensor is not enabled the point will not be stored.
 * @param location The location object to store
 * @param desired accuracy, used to check if the new point should be accepted or not
 * @return returns whether the new location point was accepted. Note that if the sensor is not enabled the point will not be stored.
 */
- (BOOL) storeLocation: (CLLocation *) location withDesiredAccuracy: (int) desiredAccuracy;
@end
