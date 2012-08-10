//
//  dataStore.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/16/11.
//  Copyright 2011 Almende. All rights reserved.
//

@protocol DataStore
- (void) commitFormattedData:(NSDictionary*)data forSensorId:(NSString*)sensorClass;
@end
