//
//  dataStore.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/16/11.
//  Copyright 2011 Almende. All rights reserved.
//

static NSString* const kNewSensorDataNotification = @"NewSensorDataNotification";
@protocol DataStore
- (void) commitFormattedData:(NSDictionary*)data forSensorId:(NSString*)sensorClass;
@end
