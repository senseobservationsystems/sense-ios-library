//
//  SingletonByChoice.m
//
//  This class provides basic Singleton By Choice functionality.
//  It is intended for use as a parent class for singletons.
//

#import "SingletonByChoice.h"

@implementation SingletonByChoice

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken = 0;
    
    __strong static id _sharedObject = nil;
    dispatch_once(&onceToken, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

@end
