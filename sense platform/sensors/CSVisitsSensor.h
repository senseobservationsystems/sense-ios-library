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
 * Sensor for storing visits
 */
@interface CSVisitsSensor : CSSensor {
}

/**
 * Processes a new visit object and stores it in the sensor. If the sensor is not enabled the point will not be stored.
 * @param visit The visit object
 */
- (void) storeVisit: (CLVisit *) visit;

@end
