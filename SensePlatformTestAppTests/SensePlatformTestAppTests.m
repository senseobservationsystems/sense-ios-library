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

#import "SensePlatformTestAppTests.h"
#import "NSString+MD5Hash.h"
#import "CSSensePlatform.h"

static NSString* const user = @"unittesttestuser_958344";
static NSString* const password = @";jadsf8wurljksdfw3rw";

@implementation SensePlatformTestAppTests

- (void)setUp
{
    [super setUp];
    
    //TODO: delete the user used for the test
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testPostAndRetrieveUseCase
{
    [CSSensePlatform initialize];
    //[CSSensePlatform registerUser:user withPassword:password];
    [CSSensePlatform loginWithUser:@"pim" andPassword:@"sensedroid"];
    NSString* name = @"TestSensor";
    NSString* value = @"Some value";
    NSDate* timestamp = [NSDate date];
    [CSSensePlatform addDataPointForSensor:name displayName:name deviceType:name dataType:kCSDATA_TYPE_STRING value:value timestamp:timestamp];
    //[CSSensePlatform flushData];

    //let's be nice and give it some time
    //[NSThread sleepForTimeInterval:15];
    
    //get data from CommonSense
    NSArray* data = [CSSensePlatform getDataForSensor:name onlyFromDevice:NO nrLastPoints:1];
    
    NSString* rVAlue = [data[0] valueForKey:@"value"];
    NSDate* rTimestamp = [NSDate dateWithTimeIntervalSince1970:[[data[0] valueForKey:@"date"] doubleValue]];
    NSTimeInterval dt = [timestamp timeIntervalSinceDate:rTimestamp];
                        
    if (data && [data count] == 1 && [value isEqualToString:rVAlue] && dt < 0.01) {
        return;
    }
    STFail(@"Didn't get the data from Common Sense");
}

@end
