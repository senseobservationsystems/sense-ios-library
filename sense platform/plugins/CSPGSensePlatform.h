//
//  PGSensePlatform.h
//  fiqs
//
//  Created by Steven on 11/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>

@interface CSPGSensePlatform : CDVPlugin {
    NSString* callbackId;  
}

@property (nonatomic, copy) NSString* callbackId;

- (void) init:(CDVInvokedUrlCommand*) command;
- (void) change_login:(CDVInvokedUrlCommand*) command;
- (void) logout:(CDVInvokedUrlCommand*) command;
- (void) register:(CDVInvokedUrlCommand*) command;
- (void) add_data_point:(CDVInvokedUrlCommand*) command;
- (void) flush_buffer:(CDVInvokedUrlCommand*) command;
- (void) get_commonsense_data:(CDVInvokedUrlCommand*) command;
- (void) get_data:(CDVInvokedUrlCommand*) command;
- (void) get_session:(CDVInvokedUrlCommand*) command;
- (void) get_status:(CDVInvokedUrlCommand*) command;
- (void) get_pref:(CDVInvokedUrlCommand*) command;
- (void) give_feedback:(CDVInvokedUrlCommand*) command;
- (void) set_pref:(CDVInvokedUrlCommand*) command;
- (void) toggle_ambience:(CDVInvokedUrlCommand*) command;
- (void) toggle_external:(CDVInvokedUrlCommand*) command;
- (void) toggle_main:(CDVInvokedUrlCommand*) command;
- (void) toggle_motion:(CDVInvokedUrlCommand*) command;
- (void) toggle_neighdev:(CDVInvokedUrlCommand*) command;
- (void) toggle_phonestate:(CDVInvokedUrlCommand*) command;
- (void) toggle_position:(CDVInvokedUrlCommand*) command;
@end
