//
//  Settings.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>

//notifications
NSString* const CSsettingLoginChangedNotification;
NSString* const settingSynchronisationChangedNotification;
NSString* const CSanySettingChangedNotification;

//setting types
NSString* const kCSSettingTypeGeneral;
NSString* const kCSSettingTypeBiometric;
NSString* const kCSSettingTypeLocation;
NSString* const kCSSettingTypeSpatial;
NSString* const kCSSettingTypeAmbience;


//general settings
NSString* const kCSGeneralSettingUsername;
NSString* const kCSGeneralSettingPassword;
NSString* const kCSGeneralSettingSenseEnabled;
NSString* const kCSGeneralSettingUploadInterval;
NSString* const kCSGeneralSettingPollInterval;
NSString* const kCSGeneralSettingAutodetect;
NSString* const kCSGeneralSettingUploadToCommonSense;

//biometric settings
NSString* const kCSBiometricSettingGender;
NSString* const kCSBiometricSettingBirthDate;
NSString* const kCSBiometricSettingWeight;
NSString* const kCSBiometricSettingHeight;
NSString* const kCSBiometricSettingBodyFat;
NSString* const kCSBiometricSettingMaxPulse;


//activity settings
NSString* const kCSActivitySettingDetection;
NSString* const kCSActivitySettingPrivacy;

//location settings
NSString* const kCSLocationSettingAccuracy;
NSString* const kCSLocationSettingMinimumDistance;

//spatial settings
NSString* const kCSSpatialSettingInterval;
NSString* const kCSSpatialSettingFrequency;
NSString* const kCSSpatialSettingNrSamples;

//ambience settings
NSString* const kCSAmbienceSettingInterval;


//Most settings are numbers (with SI units, i.e. seconds, meters, kg, percent etc.). Categorical values should be one of the following strings
//boolean
NSString* const kCSSettingYES;
NSString* const kCSSettingNO;

//upload interval
NSString* const kCSGeneralSettingUploadIntervalNightly;
NSString* const kCSGeneralSettingUploadIntervalWifi;
NSString* const kCSGeneralSettingUploadIntervalAdaptive;

//biometric
NSString* const kCSBiometricSettingGenderMale;
NSString* const kCSBiometricSettingGenderFemale;

//activity detection
NSString* const kCSActivitySettingDetectionDetectOnly;
NSString* const kCSActivitySettingDetectionIgnore;
NSString* const kCSActivitySettingDetectionDetectAndUpload;

//activity privacy
NSString* const kCSActivitySettingPrivacyPrivate;
NSString* const kCSActivitySettingPrivacyFriends;
NSString* const kCSActivitySettingPrivacyFriendsOfFriends;
NSString* const kCSActivitySettingPrivacyActivitiesCommunity;
NSString* const kCSActivitySettingPrivacyPublic;


@interface CSSetting : NSObject
{
	NSString* name;
	NSString* value;
}

@property (copy) NSString* name;
@property (copy) NSString* value;

@end


@interface CSSettings : NSObject {

}
+ (CSSettings*) sharedSettings;

//notification names
+ (NSString*) enabledChangedNotificationNameForSensor:(NSString*) sensor;
+ (NSString*) settingChangedNotificationNameForSensor:(NSString*) sensor;
+ (NSString*) settingChangedNotificationNameForType:(NSString*) type;

//sensor enables
- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable;
- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable permanent:(BOOL) permanent;
- (BOOL) isSensorEnabled:(NSString*) sensor;

//send notification to a specific sensor
- (void) sendNotificationForSensor:(NSString*) sensor;

//getter and setters for settings
- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting;
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value;
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent;

//used to set individual settings, returns whether the setting was accepted
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;
@end
