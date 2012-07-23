//
//  PreferencesSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 5/18/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sensor.h"


@interface PreferencesSensor : Sensor {

}
- (void) commitPreference:(NSNotification*) notification;

@end
