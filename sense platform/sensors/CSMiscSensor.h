//
//  MiscSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 5/24/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"


@interface CSMiscSensor : CSSensor {

}
- (void) proximityStateChanged:(NSNotification*) notification;
- (void) becameActive:(NSNotification*) notification;
- (void) becomesInactive:(NSNotification*) notification;


@end
