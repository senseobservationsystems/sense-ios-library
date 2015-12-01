//
//  DSECallback.m
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/12/15.
//
//

#import <Foundation/Foundation.h>
#import "DSECallback.h"

@implementation DSECallback {
    void (^_successHandler)();
    void (^_failureHandler)(enum DSEError);
}

- (id) initWithSuccessHandler:(void (^)()) successHandler andFailureHandler: (void (^)(enum DSEError)) failureHandler{
    _successHandler = successHandler;
    _failureHandler = failureHandler;
    return self;
}

- (void) onSuccess{
    _successHandler();
}

- (void) onFailure:(enum DSEError)error{
    _failureHandler(error);
}

@end