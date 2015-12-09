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

@interface CSSender : NSObject {
	NSString* sessionCookie;
  	@private
	NSString* username;
	NSString* passwordHash;
}

@property NSDictionary* urls;
@property NSString* sessionCookie;
@property NSString* applicationKey;

- (id) init;
- (void) setUser:(NSString*)user andPasswordHash:(NSString*) hash;
- (BOOL) isLoggedIn;

- (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass withEmail:(NSString*) email error:(NSString**) error;
/**
 *  Deprecated use loginWithError instead
 *
 *  @deprecated use loginWithError instead
 *  @return whether user is logged in or not
 */
- (BOOL) login;

/**
 *  Loggedin user to commonsense (username & password are handeled via setUser)
 *
 *  @param error error
 *
 *  @return wheter the login is successful or not
 */
- (BOOL) loginWithError:(NSError **) error;
- (NSString*) getUserId;
- (BOOL) logout;
- (NSArray*) listSensors;
- (NSArray*) listSensorsForDevice:(NSDictionary*)device;
- (NSDictionary*) createSensorWithDescription:(NSDictionary*) description;
- (BOOL) connectSensor:(NSString*)sensorId ToDevice:(NSDictionary*) device;
- (BOOL) uploadData:(NSArray*) data forSensorId:(NSString*)sensorId;
- (BOOL) uploadDataForMultipleSensors:(NSArray*) data;
- (BOOL) shareSensor: (NSString*)sensorId WithUser:(NSString*)user;
- (NSArray*) getDataFromSensor: (NSString*)sensorId nrPoints:(NSInteger) nrPoints;
- (BOOL) giveFeedbackToStateSensor:(NSString*)sensorId from:(NSDate*) from to:(NSDate*)to label:(NSString*) label;
@end