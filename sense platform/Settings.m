//
//  Settings.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "Settings.h"

//notifications
NSString* settingLoginChangedNotification = @"settingLoginChangedNotification";
NSString* anySettingChangedNotification = @"anySettingChangedNotification";

//setting types
NSString* kSettingTypeGeneral = @"general";
NSString* kSettingTypeBiometric = @"biometric";
NSString* kSettingTypeActivity = @"activity";
NSString* kSettingTypeLocation = @"position";
NSString* kSettingTypeSpatial = @"spatial";
NSString* kSettingTypeAmbience = @"ambience";

//general settings keys
NSString* kGeneralSettingSenseEnabled = @"senseEnabled";
NSString* kGeneralSettingUsername = @"username";
NSString* kGeneralSettingPassword = @"password";
NSString* kGeneralSettingUploadInterval = @"synchronisationRate";
NSString* kGeneralSettingPollInterval = @"pollRate";
NSString* kGeneralSettingAutodetect = @"auto detect";
NSString* kGeneralSettingUploadToCommonSense = @"upload to CommonSense";

//biometric settings
NSString* kBiometricSettingGender = @"gender";
NSString* kBiometricSettingBirthDate = @"birth date";
NSString* kBiometricSettingWeight = @"weight";
NSString* kBiometricSettingHeight = @"height";
NSString* kBiometricSettingBodyFat = @"body fat";
NSString* kBiometricSettingMaxPulse = @"max pulse";

//activity settings
NSString* kActivitySettingDetection = @"detection";
NSString* kActivitySettingPrivacy = @"privacy";

//location settings keys
NSString* kLocationSettingAccuracy = @"accuracy";
NSString* kLocationSettingMinimumDistance = @"minimumDistance";

//spatial settings
NSString* kSpatialSettingInterval = @"pollInterval";
NSString* kSpatialSettingFrequency = @"frequency";
NSString* kSpatialSettingNrSamples = @"number of samples";

//ambiance settings
NSString* kAmbienceSettingInterval = @"pollInterval";

//categorical values
NSString* kSettingYES = @"1";
NSString* kSettingNO = @"0";

NSString* kGeneralSettingUploadIntervalNightly = @"nightly";
NSString* kGeneralSettingUploadIntervalWifi = @"wifi";
NSString* kGeneralSettingUploadIntervalAdaptive = @"adaptive";

//biometric
NSString* kBiometricSettingGenderMale = @"male";
NSString* kBiometricSettingGenderFemale = @"female";

//activity detection
NSString* kActivitySettingDetectionDetectOnly = @"detect only";
NSString* kActivitySettingDetectionIgnore = @"ignore";
NSString* kActivitySettingDetectionDetectAndUpload = @"detect and upload";

//activity privacy
NSString* kActivitySettingPrivacyPrivate = @"private";
NSString* kActivitySettingPrivacyFriends = @"friends";
NSString* kActivitySettingPrivacyFriendsOfFriends = @"friends of friends";
NSString* kActivitySettingPrivacyActivitiesCommunity = @"activities community";
NSString* kActivitySettingPrivacyPublic = @"public";

@implementation Setting
@synthesize name;
@synthesize value;
@end


@interface Settings (private) 
- (void) storeSettings;
- (void) loadSettingsFromPath:(NSString*)path;
- (void) anySettingChanged:(NSString*)setting value:(NSString*)value;
@end

@implementation Settings {
@private NSMutableDictionary* settings;
@private NSMutableDictionary* general;
@private NSMutableDictionary* location;
@private NSMutableDictionary* sensorEnables;
}
//@synthesize general;
//@synthesize location;

//Singleton instance
static Settings* sharedSettingsInstance = nil;

+ (Settings*) sharedSettings {
	if (sharedSettingsInstance == nil) {
		sharedSettingsInstance = [[super allocWithZone:NULL] init];
	}
	return sharedSettingsInstance;	
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedSettings];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id) init {
	self = [super init];
	if (self) {
		//initialise settings from plist
        NSString* plistPath;
		
		//Try to load saved settings
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
        plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
			//fallback to default settings
			plistPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        }
		@try {
			[self loadSettingsFromPath:plistPath];
		}
		@catch (NSException * e) {
			NSLog(@"Settings: exception thrown while loading settings: %@", e);
			settings = nil;
		}
		if (settings == nil) {
			//fall back to defaults
			@try {
				[self loadSettingsFromPath:[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"]];
			}
			@catch (NSException * e) {
				NSLog(@"Settings: exception thrown while loading default settings. THIS IS VERY SERIOUS: %@", e);
				settings = nil;
			}
		}
        [self ensureLatestVersion];
	}
	return self;
}

#pragma mark - 
#pragma mark Settings

+ (NSString*) enabledChangedNotificationNameForSensor:(NSString*) sensor {
	return [NSString stringWithFormat:@"%@EnabledChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForSensor:(NSString*) sensor {
	return [NSString stringWithFormat:@"%@SettingChangedNotification", sensor];
}

+ (NSString*) settingChangedNotificationNameForType:(NSString*) type {
	return [NSString stringWithFormat:@"%@SettingChangedNotificationType", type];
}

- (BOOL) isSensorEnabled:(NSString*) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	return enabled;
}

- (void) sendNotificationForSensor:(NSString*) sensor {
	NSString* key = [NSString stringWithFormat:@"%@", sensor];
	id object = [sensorEnables objectForKey:key];
	BOOL enabled = object == nil? NO : [object boolValue];
	NSNumber* enableObject = [NSNumber numberWithBool:enabled];
	
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
}

- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable {
    return [self setSensor:sensor enabled:enable permanent:YES];
}

- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable permanent:(BOOL) permanent {
	NSNumber* enableObject = [NSNumber numberWithBool:enable];
    NSString* key = [NSString stringWithFormat:@"%@", sensor];
    if (permanent) {
        //store enable settings
        [sensorEnables setObject:enableObject forKey:key];
        //write back to file
        [self storeSettings];
    }
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] enabledChangedNotificationNameForSensor:sensor] object:enableObject]];
	[self anySettingChanged:key value:enable?@"true":@"false"];
	return YES;
}

- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password {
    NSLog(@"Settings setLogin:%@", user);
    [self setSettingType:kSettingTypeGeneral setting:kGeneralSettingUsername value:user];
    [self setSettingType:kSettingTypeGeneral setting:kGeneralSettingPassword value:password];
	//notify registered subscribers
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:settingLoginChangedNotification object:nil]];
	return YES;
}


- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting {
	NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
	NSMutableDictionary* typeSettings = [settings valueForKey:name];
	if (typeSettings != nil) {
		return [typeSettings objectForKey: setting];
	}
	return nil;
}

- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value {
    return [self setSettingType:type setting:setting value:value persistent: YES];
}

- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent {
    if (persistent) {
        //get sensor settings;
        NSString* name = [NSString stringWithFormat:@"SettingsType%@", type];
        NSMutableDictionary* typeSettings = [settings valueForKey:name];
        if (typeSettings == nil) {
            //create if it doesn't already exist
            typeSettings = [NSMutableDictionary new];
            [settings setObject:typeSettings forKey:name];
        }
        
        //commit setting
        [typeSettings setObject:value forKey:setting];
        [self storeSettings];
    }
	
	//create notification object
	Setting* notificationObject = [[Setting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:[[self class] settingChangedNotificationNameForType:type] object:notificationObject]];
	[self anySettingChanged:setting value:value];
	
	//free
	
	return YES;
}



#pragma mark -
#pragma mark Private

- (void) anySettingChanged:(NSString*)setting value:(NSString*)value {
	//create notification object
	Setting* notificationObject = [[Setting alloc] init];
	notificationObject.name = setting;
	notificationObject.value = value;
	
	//send notification
	[[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:anySettingChangedNotification object:notificationObject]];
	
}

- (void) loadSettingsFromPath:(NSString*)path {
	NSLog(@"Loading settings from %@", path);
	NSString* errorDesc = nil;
	NSPropertyListFormat format;
	
	NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:path];
	settings = (NSMutableDictionary *)[NSPropertyListSerialization
									   propertyListFromData:plistXML
									   mutabilityOption:NSPropertyListMutableContainersAndLeaves
									   format:&format
									   errorDescription:&errorDesc];
	if (!settings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
	//instantiate subsections of settings
	general = [settings valueForKey:@"general"];
	location = [settings valueForKey:@"location"];
	sensorEnables = [settings valueForKey:@"sensorEnables"];
	if (sensorEnables == nil) {
		sensorEnables = [NSMutableDictionary new];
		[settings setObject:sensorEnables forKey:@"sensorEnables"];
	}
}

- (void) storeSettings {
	@try {
		NSString *error;
		NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		NSString *plistPath = [rootPath stringByAppendingPathComponent:@"Settings.plist"];
		NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:settings
																	   format:NSPropertyListXMLFormat_v1_0
															 errorDescription:&error];
		if(plistData) {
			[plistData writeToFile:plistPath atomically:YES];
		}
		else {
			NSLog(@"%@", error);
		}
	}
	@catch (NSException * e) {
		NSLog(@"Settings:Exception thrown while storing settings: %@", e);
	}
}

- (void) ensureLatestVersion {
    //open default settings
    NSString* errorDesc = nil;
	NSPropertyListFormat format;
    NSString* defaultPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
    NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:defaultPath];
	NSDictionary* defaultSettings = (NSDictionary *)[NSPropertyListSerialization
                                                     propertyListFromData:plistXML
                                                     mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                     format:&format
                                                     errorDescription:&errorDesc];
	if (!defaultSettings)
	{
		NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
		return;
	}
    
    //copy settings that aren't in the local settings with the default settings
    
    for (NSString* key in defaultSettings) {
        if ([settings valueForKey:key] == nil) {
            [settings setValue:[defaultSettings objectForKey:key] forKey:key];
        }
    }
    
}
@end
