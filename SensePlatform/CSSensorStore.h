/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "CSDataStore.h"
#import "CSSender.h"
#import "CSSensor.h"

#import <UIKit/UIKit.h>
#import "UIDevice+IdentifierAddition.h"
#import "UIDevice+Hardware.h"

/**
 Handles sensor data storing and uploading. Start all sensors and data providers.
 
 Data is stored locally for 30 days. After a succesfull upload, older data is removed.
 */
@interface CSSensorStore : NSObject <CSDataStore> {
}

@property (readonly) NSArray* allAvailableSensorClasses;
@property (readonly) NSArray* sensors;
@property (readonly) CSSender* sender;


+ (CSSensorStore*) sharedSensorStore;
+ (NSDictionary*) device;

- (id)init;
- (void) initializeDSEWithSessionId: (NSString*) sessionId andUserId:(NSString*) userId andAppKey:(NSString*) appKey completeHandler:(void (^)()) completeHandler failureHandler: (void (^)()) failureHandler;
- (void) loginChanged;
- (void) setEnabled:(BOOL) enable;
- (void) enabledChanged:(id) notification;

/* Ensure all sensor data is flushed, used to reduce memory usage.
 * Flushing in this order, on failure continue with the next:
 * - flush to server
 * - flush to disk 
 */
- (void) forceDataFlushWithSuccessCallback: (void(^)()) successCallback failureCallback:(void(^)(NSError*)) failureCallback;

- (void) generalSettingChanged: (NSNotification*) notification;

// passes on the requestLocationPermission function call to the locationProvider
- (void) requestLocationPermission;
// passes on the locationPermissionState function to the locationProvider
- (CLAuthorizationStatus) locationPermissionState;

@end
