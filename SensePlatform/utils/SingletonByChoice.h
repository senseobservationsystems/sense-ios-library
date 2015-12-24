//
//  SingletonByChoice.h
//
//  This class provides basic Singleton By Choice functionality.
//  It is intended for use as a parent class for singletons.

#import <Foundation/Foundation.h>

@interface SingletonByChoice : NSObject

+ (instancetype)sharedInstance;

@end