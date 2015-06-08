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
 * Sensor for storing location updates. Every time a new update comes in, it is stored. The rate with which updates come in is up to iOS. 
 
 Note that when the cortex auto pausing feature is enabled updates are limited to once every three minutes.
 
 ___JSON output value format___
 
	 {
		 "longitude": FLOAT;
		 "latitude": FLOAT;
		 "altitude": FLOAT;
		 "accuracy": FLOAT;
         "vertical accuracy:" FLOAT;
		 "speed": FLOAT;
	 }
 
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
