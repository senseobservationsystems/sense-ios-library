//
//  DSECallback.h
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/12/15.
//
//

@import DSESwift;

@interface DSECallback : NSObject <DSEAsyncCallback>

- (id) initWithSuccessHandler:(void (^)()) successHandler andFailureHandler: (void (^)(enum DSEError)) failureHandler;
- (void)onSuccess;
- (void)onFailure:(enum DSEError)error;

@end