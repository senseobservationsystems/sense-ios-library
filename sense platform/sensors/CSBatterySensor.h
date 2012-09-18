//
//  BatterySensor.h
//  senseApp
//
//  Created by Pim Nijdam on 2/25/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"

@interface CSBatterySensor : CSSensor {
}

- (void) commitBatteryState:(NSNotification*) notification;
@end
