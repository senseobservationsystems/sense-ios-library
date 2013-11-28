//
//  CSScreenSensor.h
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSSensor.h"

@interface CSScreenSensor : CSSensor

- (void) commitDisplayState:(BOOL) isScreenTurnedOn;

@end
