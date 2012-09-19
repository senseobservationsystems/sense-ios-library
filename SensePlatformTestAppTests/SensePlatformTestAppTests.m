//
//  SensePlatformTestAppTests.m
//  SensePlatformTestAppTests
//
//  Created by Pim Nijdam on 9/19/12.
//
//

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
