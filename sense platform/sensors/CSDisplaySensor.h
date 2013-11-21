//
//  CSDisplaySensor.h
//  SensePlatform
//
//  Created by Platon Efstathiadis on 11/20/13.
//
//

#import "CSSensor.h"

@interface CSDisplaySensor : CSSensor

- (void) commitDisplayState:(BOOL) isScreenTurnedOn;

@end
