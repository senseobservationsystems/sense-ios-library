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

#import "CSSensor.h"

@interface CSDynamicSensor : CSSensor {
    NSString* sensorName;
    NSString* displayName;
    NSString* deviceType;
    NSString* dataType;
}
- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields;
- (id) initWithName:(NSString*) name displayName:(NSString*) dispName deviceType:(NSString*)devType dataType:(NSString*) datType fields:(NSDictionary*) fields device:(NSDictionary*) device;
- (void) commitValue:(NSString*)value withTimestamp:(NSTimeInterval)timestamp;
@end

