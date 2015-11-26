//
//  CSDataPoint.h
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import <Foundation/Foundation.h>

@interface CSDataPoint : NSObject {
}

- (NSDictionary*) device;
- (NSDictionary*) timeValueDict;

@property long long dataPointID; //This is being set by CSStorage.
@property NSDate* timestamp;
@property NSString* sensor;
@property NSString* sensorDescription;
@property NSString* deviceType;
@property NSString* deviceUUID;
@property NSString* dataType;
@property NSString* timeValue; //json {"date":<unix timestamp>, "value":<value>}
@end
