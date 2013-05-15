//
//  PGSensePlatform.m
//  fiqs
//
//  Created by Steven on 11/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "CSPGSensePlatform.h"
#import <SensePlatform/CSSensePlatform.h>
#import <SensePlatform/CSSettings.h>

@implementation CSPGSensePlatform {
    BOOL locationGps;
    BOOL locationNetwork;
}

@synthesize callbackId;

- (void) init:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: init");
    
    //init sense platform
    [CSSensePlatform initialize];
    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) change_login:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: change_login");
    
    NSString* username = [command.arguments objectAtIndex:0];
    NSString* hash = [command.arguments objectAtIndex:1];
    
    bool succes = [CSSensePlatform loginWithUser:username andPasswordHash:hash];
    
    CDVPluginResult* pluginResult;
    if (succes)
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    else
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) register:(CDVInvokedUrlCommand*) command;{
    NSLog(@"PGSensePlatform: register");
    
    NSString* username = [command.arguments objectAtIndex:0];
    NSString* password = [command.arguments objectAtIndex:1];
    
    bool succes = [CSSensePlatform registerUser:username withPassword:password withEmail:nil];
    //    BOOL success = [[CSSensorStore sharedSensorStore].sender registerUser:username withPassword:password error:&error];
    
    CDVPluginResult* pluginResult;
    
    if (succes)
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    else
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Failed to register user"];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];    
}

- (void) logout:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: logout");
    
    [CSSensePlatform logout];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) add_data_point:(CDVInvokedUrlCommand*) command {
        NSLog(@"PGSensePlatform: add_data_point");

    NSString* sensorName = [command.arguments objectAtIndex:0];
    NSString* displayName = [command.arguments objectAtIndex:1];
    NSString* description = [command.arguments objectAtIndex:2];
    NSString* dataType = [command.arguments objectAtIndex:3];
    NSString* value = [command.arguments objectAtIndex:4];
    NSTimeInterval timestamp = [[command.arguments objectAtIndex:5] doubleValue] / 1000; //convert from milliseconds
    
    [CSSensePlatform addDataPointForSensor:sensorName displayName:displayName deviceType:description dataType:dataType value:value timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) flush_buffer:(CDVInvokedUrlCommand*) command {
    [CSSensePlatform flushData];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void) get_data:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: get_data");

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    /*
    NSString* name = [command.arguments objectAtIndex:1];
    NSDictionary* data = [[CSSensorStore sharedSensorStore] getCachedDataForSensor:name];
    NSLog(@"Data: %@", data);
    if (data == NULL || data == nil) {
        data = [NSDictionary new];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     */
}

- (void) get_commonsense_data:(CDVInvokedUrlCommand*) command {
    
    NSString* sensor = [command.arguments objectAtIndex:0];
    BOOL onlyThisDevice = [[command.arguments objectAtIndex:1] boolValue];
    NSArray* data = [CSSensePlatform getDataForSensor:sensor onlyFromDevice:onlyThisDevice nrLastPoints:100];
    
    NSMutableArray* results = [[NSMutableArray alloc] initWithCapacity:[data count]];
    for (NSDictionary* entry in data) {
        //convert to milliseconds as java script expects this
        NSTimeInterval date = [[entry objectForKey:@"date"] doubleValue] * 1000;
        NSMutableDictionary* newEntry = [entry mutableCopy];
        [newEntry setValue:[NSNumber numberWithDouble:date] forKey:@"date"];
        //Obsolete, just add this to test with old sense_platform.js
        [newEntry setValue:[NSNumber numberWithDouble:date] forKey:@"timestamp"];
        [results addObject:newEntry];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) get_session:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: get_session");
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) get_status:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: get_status");

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) get_pref:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: get_pref");
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
- (void) give_feedback:(CDVInvokedUrlCommand*) command {
    NSString* name = [command.arguments objectAtIndex:0];
    NSTimeInterval start = [[command.arguments objectAtIndex:1] unsignedLongValue];
    NSTimeInterval end = [[command.arguments objectAtIndex:2] unsignedLongValue];
    NSString* label = [command.arguments objectAtIndex:3];
    
    [CSSensePlatform giveFeedbackOnState:name from:[NSDate dateWithTimeIntervalSince1970:start] to:[NSDate dateWithTimeIntervalSince1970:end] label:label];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) set_pref:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: set_pref");
    
    NSString * key = [command.arguments objectAtIndex:0];
    NSString * value = [command.arguments objectAtIndex:1];
    
    if ([key isEqualToString:@"commonsense_rate"]) {
        // sample rate change
        if ([value isEqualToString:@"-2"]) {
            // real time
            value = @"1";
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"10"];
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"10"];
            
        } else if ([value isEqualToString:@"-1"]) {
            // often
            value = @"10";
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"10"];
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"10"];
            
        } else if ([value isEqualToString:@"0"]) {
            // normal
            value = @"60";
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"60"];
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"60"];
            
        } else if ([value isEqualToString:@"1"]) {
            // eco-mode
            value = @"900"; // 15 minutes
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"900"];
            [[CSSettings sharedSettings] setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"900"];
            
        } else {
            // something else
            NSLog(@"Incorrect preference value: %@", value);
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Unknown preference"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
    } else if ([key isEqualToString:@"sync_rate"]) {
        // sync rate change
        if ([value isEqualToString:@"-2"]) {
            // real time
            value = @"10";
            
        } else if ([value isEqualToString:@"-1"]) {
            // often
            value = @"60";
            
        } else if ([value isEqualToString:@"0"]) {
            // normal
            value = @"300"; // 5 minutes
            
        } else if ([value isEqualToString:@"1"]) {
            // eco-mode
            value = @"1800"; // 30 minutes
            
        } else {
            // something else
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Unknown sync rate"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        // set the sync rate
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval value:value];
        
    } else if ([key isEqualToString:@"location_gps"]) {
        locationGps = [value boolValue];
        [self updateLocationSetting];
    } else if ([key isEqualToString:@"location_network"]) {
        locationNetwork = [value boolValue];
        [self updateLocationSetting];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) updateLocationSetting {
    if (locationNetwork == NO && locationGps == NO) {
        [[CSSettings sharedSettings] setSensor:kCSSENSOR_LOCATION enabled:NO];
    } else if (locationNetwork == NO && locationGps == YES) {
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"0"];
        [[CSSettings sharedSettings] setSensor:kCSSENSOR_LOCATION enabled:YES];
    } else if (locationNetwork == YES && locationGps == NO) {
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"100"];
        [[CSSettings sharedSettings] setSensor:kCSSENSOR_LOCATION enabled:YES];
    } else if (locationNetwork == YES && locationGps == YES) {
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"0"];
        [[CSSettings sharedSettings] setSensor:kCSSENSOR_LOCATION enabled:YES];
    }
}

- (void) toggle_ambience:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_ambience");
    
    BOOL active = [[command.arguments objectAtIndex:0] boolValue];
    
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_NOISE enabled:active];
    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_external:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_external");
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_main:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_main");
    
    BOOL active = [[command.arguments objectAtIndex:0] boolValue];
    
    [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingSenseEnabled value:active? kCSSettingYES:kCSSettingNO];

    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_motion:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_motion");
    
    BOOL active = [[command.arguments objectAtIndex:0] boolValue];
    
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_ACCELERATION enabled:active];
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_ACCELEROMETER enabled:active];
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_ROTATION enabled:active];
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_ORIENTATION enabled:active];
    
    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_neighdev:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_neighdev");
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_INVALID_ACTION messageAsString:@"Not implemented"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_phonestate:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_phonestate");
    
    BOOL active = [[command.arguments objectAtIndex:0] boolValue];
    
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_BATTERY enabled:active];
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_CALL enabled:active];
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_CONNECTION_TYPE enabled:active];
    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) toggle_position:(CDVInvokedUrlCommand*) command {
    NSLog(@"PGSensePlatform: toggle_position");
    
    
    BOOL active = [[command.arguments objectAtIndex:0] boolValue];
    
    [[CSSettings sharedSettings] setSensor:kCSSENSOR_LOCATION enabled:active];
    
    // return result
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end
