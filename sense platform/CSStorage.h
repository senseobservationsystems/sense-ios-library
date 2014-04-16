//
//  CSStorage.h
//  SensePlatform
//
//  Created by Pim Nijdam on 11/04/14.
//
//

#import <Foundation/Foundation.h>

@interface CSStorage : NSObject
- (id) initWithPath:(NSString*) databaseFilePath;
- (void) storeSensor:(NSString*) sensor description:(NSString*) description deviceType:(NSString*) deviceType device:(NSString*) device dataType:(NSString*) dataType value:(NSString*) value timestamp:(double) timestamp;
- (NSArray*) getSensorDataPointsFromId:(long long) start limit:(size_t) limit;
- (void) removeDataBeforeId:(long long) rowId;
- (long long) getLastDataPointId;
- (void) flush;
@end
