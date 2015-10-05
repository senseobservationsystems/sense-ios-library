//
//  NSNotificationSensor+MainThread.h
//  activityracker
//
//  Created by Pim Nijdam on 3/12/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNotificationCenter (CSMainThread)

- (void)postNotificationOnMainThread:(NSNotification *)notification;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject;
- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

- (void)postNotificationOnBackgroundThread:(NSNotification *)notification;
- (void)postNotificationOnBackgroundThreadName:(NSString *)aName object:(id)anObject;
- (void)postNotificationOnBackgroundThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
@end
