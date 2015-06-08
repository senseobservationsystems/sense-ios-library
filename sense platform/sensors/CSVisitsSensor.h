//
//  CSVisitsSensor.h
//  SensePlatform
//
//  Created by Joris Janssen on 26/02/15.
//
//

#import "CSSensor.h"
#import <CoreLocation/CoreLocation.h>

/**
 * Sensor for storing visits. Visits can be recorded automatically by iOS from iOS 8 and later. Each visit consits of a location and departure and arrival time. This sensor stores each arrival and departure event, which can than later be used to calculate time at a certain location, or time travelling. 
 
 ___JSON output value format___
 
	 {
		 "longitude": FLOAT;
		 "lattitude": FLOAT;
		 "accuracy": FLOAT;
		 "event": STRING; //"departure", "arrival"
	 }

 
 */
@interface CSVisitsSensor : CSSensor {
}

/**
 * Processes a new visit object and stores it in the sensor. If the sensor is not enabled the point will not be stored.
 * @param visit The visit object
 */
- (void) storeVisit: (CLVisit *) visit;

@end
