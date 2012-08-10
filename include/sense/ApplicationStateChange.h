//
//  ApplicationStateChange.h
//  sensePlatform
//
//  Created by Pim Nijdam on 11/1/11.
//  Copyright (c) 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const applicationStateChangeNotification;

typedef enum {
    kUPLOAD_OK=0,
    kUPLOAD_FAILED=1,
} ApplicationStateChange;

@interface ApplicationStateChangeMsg : NSObject {
    ApplicationStateChange stateChange;
}
@property (assign) ApplicationStateChange applicationStateChange;
@end
