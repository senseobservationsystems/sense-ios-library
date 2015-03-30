//
//  CSScreenSensor.h
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSSensor.h"

/**
 Sensor storing screen activity data. Currently stores whether the is turned on or turned off. This sensor is event based and only stores data upon changes.
 
 ___JSON output value format___
 
	{
		"screen": STRING; //"on", "off"
	}
 
 */
@interface CSScreenSensor : CSSensor

/** Stores state of the screen.
 @param isScreenTurnedOn Boolean describing if screen is on/off.
 */
- (void) commitDisplayState:(BOOL) isScreenTurnedOn;

@end
