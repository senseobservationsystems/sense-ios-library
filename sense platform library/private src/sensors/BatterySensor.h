//
//  BatterySensor.h
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sensor.h"

@interface BatterySensor : Sensor {
}

- (void) commitBatteryState:(NSNotification*) notification;
@end
