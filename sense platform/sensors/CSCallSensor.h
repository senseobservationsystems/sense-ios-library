//
//  callSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 4/19/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"
#import <CoreTelephony/CTCallCenter.h>


@interface CSCallSensor : CSSensor {
	CTCallCenter* callCenter;
}

@end
