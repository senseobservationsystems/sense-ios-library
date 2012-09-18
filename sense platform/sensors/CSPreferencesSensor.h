//
//  PreferencesSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 5/18/11.
//  Copyright 2011 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSSensor.h"


@interface CSPreferencesSensor : CSSensor {

}
- (void) commitPreference:(NSNotification*) notification;

@end
