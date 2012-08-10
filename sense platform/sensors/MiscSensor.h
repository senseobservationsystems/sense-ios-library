//
//  MiscSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 5/24/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sensor.h"


@interface MiscSensor : Sensor {

}
- (void) proximityStateChanged:(NSNotification*) notification;
- (void) becameActive:(NSNotification*) notification;
- (void) becomesInactive:(NSNotification*) notification;


@end
