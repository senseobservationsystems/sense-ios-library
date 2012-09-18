//
//  OrientationSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 2/28/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"


@interface CSOrientationStateSensor : CSSensor {

}


- (void) commitOrientation:(NSNotification*) notification;


@end
