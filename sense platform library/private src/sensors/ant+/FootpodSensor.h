//
//  FootpodSensor.h
//  sensePlatform
//
//  Created by Pim Nijdam on 4/2/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "Sensor.h"
#import <WFConnector/WFConnector.h>

@interface FootpodSensor : Sensor <WFSensorConnectionDelegate>

- (id) initWithConnection:(WFSensorConnection*) connection;
- (void) checkData;
@end