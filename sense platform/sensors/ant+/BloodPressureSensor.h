//
//  BloodPressureSensor.h
//  sensePlatform
//
//  Created by Pim Nijdam on 4/17/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//
#if 0
#import "Sensor.h"
#import "SensePlatform.h"
#import <WFConnector/WFAntFS.h>

@interface BloodPressureSensor : Sensor <WFAntFSDeviceDelegate>
- (void) syncMeasurements:(bpmCallBack) cb;
@end

#endif
