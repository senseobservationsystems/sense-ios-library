//
//  NSNotificationSensor+MainThread.m
//  activityracker
//
//  Created by Pim Nijdam on 3/12/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import "NSNotificationCenter+MainThread.h"
@implementation NSNotificationCenter (MainThread)

static dispatch_queue_t backgroundQueue = nil;

//post notification on main thread
- (void)postNotificationOnMainThread:(NSNotification *)notification
{
	[self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject];
	[self postNotificationOnMainThread:notification];
}

- (void)postNotificationOnMainThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
	[self postNotificationOnMainThread:notification];
}

//post notification on background thread
- (void)postNotificationOnBackgroundThread:(NSNotification *)notification
{
    if (backgroundQueue == nil)
        backgroundQueue = dispatch_queue_create("com.sense.backgroundNotification", NULL);
    
    dispatch_async(backgroundQueue, ^{
        [self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
    });
}

- (void)postNotificationOnBackgroundThreadName:(NSString *)aName object:(id)anObject
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject];
	[self postNotificationOnBackgroundThread:notification];
}

- (void)postNotificationOnBackgroundThreadName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo
{
	NSNotification *notification = [NSNotification notificationWithName:aName object:anObject userInfo:aUserInfo];
	[self postNotificationOnBackgroundThread:notification];
}
@end