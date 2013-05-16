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

#import "NSNotificationCenter+MainThread.h"
@implementation NSNotificationCenter (CSMainThread)

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
        @autoreleasepool {

        [self performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
        }
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