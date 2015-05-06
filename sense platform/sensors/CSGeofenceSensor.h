//
//  GSGeofenceSensor.h
//  SensePlatform
//
//  Created by Yfke Dulek on 06/05/15.
//
//


#import <CoreLocation/CoreLocation.h>

/**
 * Sensor for storing visits to a prespecified set of locations. Visits can be recorded automatically by iOS from iOS 8 and later. This sensor stores each arrival and departure event, which can than later be used to calculate time at a certain location.
 
 ___JSON output value format___
 
 {
 TODO change this:
 "longitude": FLOAT;
 "latitude": FLOAT;
 "accuracy": FLOAT;
 "event": STRING; //"departure", "arrival"
 }
 
 
 */
@interface CSGeofenceSensor : CSSensor {
}

/**
 * Processes a new arrival/departure in/out the fence, and stores it in the sensor. If the sensor is not enabled the point will not be stored.
 * @param visit The visit object
 */
- (void) storeRegionEvent: (CLRegion *) region withEnterRegion: (BOOL) enter;

/**
 * Checks whether the given region is currently being monitored
 * @param regionId the identifier (a string, supplied when creating the region) of the region
 */
- (BOOL) isActive: (NSString*) regionId;

/**
 * Get all currently registered regions
 */
- (NSMutableArray*) activeRegions;

/**
 * Add a new region to the list of registered regions. This region will be tracked from now on whenever the geofence sensor is activated
 */
- (void) addRegion:(CLRegion*) region;

/**
 * Remove a region from registration. It will not be tracked again until it is explicitly added.
 */
- (void) removeRegion:(CLRegion*) region;

/**
 * Retrieve the region associated with the given identifier.
 */
- (CLRegion*) getRegionWithIdentifier:(NSString*) identifier;


@end
