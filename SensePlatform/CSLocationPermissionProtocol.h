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
 * Author: Freek van Polen (freek@sense-labs.com)
 */

/**
 Protocol that any object requesting location permissions through the CSSensePlatform should implement.
 After the user grants or denies permissions, one of these functions will be called on your object.
 
 Below an example of how this could be implemented in a view object:
 
 @interface TourViewController : UIViewController <CSLocationPermissionProtocol>
 @end
 
 @implementation TourViewController
 
 - (IBAction)handlePermissionButtonClick:(id)sender {
    [CSSensePlatform requestLocationPermissionWithDelegate: self];
 }
 
 - (void) locationPermissionGranted {
    [self refreshView];
 }
 
 - (void) locationPermissionDenied {
    [self refreshView];
 }
 
 - (void)viewDidLoad {
    [super viewDidLoad];
    [self refreshView];
 }
 
 - (void) refreshView {
    CLAuthorizationStatus status = [CSSensePlatform locationPermissionState];
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            break;
        case kCLAuthorizationStatusDenied:
            break;
        case kCLAuthorizationStatusNotDetermined:
            break;
        default:
            break;
    }
 }
 
@end
 
 */
@protocol CSLocationPermissionProtocol <NSObject>

/**
 Callback that will be called in the event the user grants location updates permission.
 */
- (void) locationPermissionGranted;

/**
 Callback that will be called in the event the user denies location updates permission.
 */
- (void) locationPermissionDenied;

@end