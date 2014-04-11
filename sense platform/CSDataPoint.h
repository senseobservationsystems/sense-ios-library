//
//  CSDataPoint.h
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import <Foundation/Foundation.h>

@interface CSDataPoint : NSObject {
    long long dataPointID; //This is being set by CSStorage.
    NSDate* timestamp;
    NSString* sensor;
    NSString* sensorDescription;
    NSString* deviceType;
    NSString* device;
    NSString* dataType;
    NSString* data;
}

@end
