//
//  ActivitySender.h
//  activityracker
//
//  Created by Pim Nijdam on 2/20/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ActivitySender : NSObject
- (BOOL) isLoggedIn;
- (BOOL) uploadGPX:(NSString*)gpx;
- (BOOL) updateActivityTokenFromToken:(NSString*) token;
@end
