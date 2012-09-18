//
//  ConnectionSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 4/29/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"
@class CSReachability;


@interface CSConnectionSensor : CSSensor {
	CSReachability* internetReach;
}

- (void) reachabilityChanged: (NSNotification* )note;

@end
