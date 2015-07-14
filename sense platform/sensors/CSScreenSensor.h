//
//  CSScreenSensor.h
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSSensor.h"

extern const NSString *kVALUE_IDENTIFIER_SCREEN_LOCKED;
extern const NSString *kVALUE_IDENTIFIER_SCREEN_UNLOCKED;
extern const NSString *kVALUE_IDENTIFIER_SCREEN_ONOFF_SWITCH;

/**
 Sensor storing screen activity data. Currently stores whether the is turned on or turned off. This sensor is event based and only stores data upon changes.
 
 ___JSON output value format___
 
	{
		"screen": STRING; //"on", "off"
	}
 
 */
@interface CSScreenSensor : CSSensor

/** Stores state of the screen.
 @param state Describing state of the screen according to the identifiers specified above. 
 */
- (void) commitDisplayState:(const NSString *) state;

@end
