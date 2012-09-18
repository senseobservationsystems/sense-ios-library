//
//  ApplicationStateChange.h
//  sensePlatform
//
//  Created by Pim Nijdam on 11/1/11.
//  Copyright (c) 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const CSapplicationStateChangeNotification;

typedef enum {
    kCSUPLOAD_OK=0,
    kCSUPLOAD_FAILED=1,
} CSApplicationStateChange;

@interface CSApplicationStateChangeMsg : NSObject {
    CSApplicationStateChange stateChange;
}
@property (assign) CSApplicationStateChange applicationStateChange;
@end
