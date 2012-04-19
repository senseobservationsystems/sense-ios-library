//
//  Settings.h
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/18/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>

//notifications
extern NSString* settingLoginChangedNotification;
extern NSString* settingSynchronisationChangedNotification;
extern NSString* anySettingChangedNotification;

//setting types
extern NSString* kSettingTypeGeneral;
extern NSString* kSettingTypeBiometric;
extern NSString* kSettingTypeLocation;
extern NSString* kSettingTypeSpatial;


//general settings
extern NSString* kGeneralSettingUsername;
extern NSString* kGeneralSettingPassword;
extern NSString* kGeneralSettingSenseEnabled;
extern NSString* kGeneralSettingUploadInterval;
extern NSString* kGeneralSettingPollInterval;
extern NSString* kGeneralSettingAutodetect;

//biometric settings
extern NSString* kBiometricSettingGender;
extern NSString* kBiometricSettingBirthDate;
extern NSString* kBiometricSettingWeight;
extern NSString* kBiometricSettingHeight;
extern NSString* kBiometricSettingBodyFat;
extern NSString* kBiometricSettingMaxPulse;


//activity settings
extern NSString* kActivitySettingDetection;
extern NSString* kActivitySettingPrivacy;

//location settings
extern NSString* kLocationSettingAccuracy;
extern NSString* kLocationSettingMinimumDistance;

//spatial settings
extern NSString* kSpatialSettingInterval;
extern NSString* kSpatialSettingFrequency;
extern NSString* kSpatialSettingSampleTime;


//Most settings are numbers (with SI units, i.e. seconds, meters, kg, percent etc.). Categorical values should be one of the following strings
//boolean
extern NSString* kSettingYES;
extern NSString* kSettingNO;

//upload interval
extern NSString* kGeneralSettingUploadIntervalNightly;
extern NSString* kGeneralSettingUploadIntervalWifi;
extern NSString* kGeneralSettingUploadIntervalAdaptive;

//biometric
extern NSString* kBiometricSettingGenderMale;
extern NSString* kBiometricSettingGenderFemale;

//activity detection
extern NSString* kActivitySettingDetectionDetectOnly;
extern NSString* kActivitySettingDetectionIgnore;
extern NSString* kActivitySettingDetectionDetectAndUpload;

//activity privacy
extern NSString* kActivitySettingPrivacyPrivate;
extern NSString* kActivitySettingPrivacyFriends;
extern NSString* kActivitySettingPrivacyFriendsOfFriends;
extern NSString* kActivitySettingPrivacyActivitiesCommunity;
extern NSString* kActivitySettingPrivacyPublic;


@interface Setting : NSObject
{
	NSString* name;
	NSString* value;
}

@property (copy) NSString* name;
@property (copy) NSString* value;

@end


@interface Settings : NSObject {

}
+ (Settings*) sharedSettings;

//notification names
+ (NSString*) enabledChangedNotificationNameForSensor:(Class) sensor;
+ (NSString*) settingChangedNotificationNameForSensor:(Class) sensor;
+ (NSString*) settingChangedNotificationNameForType:(NSString*) type;

//sensor enables
- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable;
- (BOOL) setSensor:(Class) sensor enabled:(BOOL) enable permanent:(BOOL) permanent;
- (BOOL) isSensorEnabled:(Class) sensor;

//send notification to a specific sensor
- (void) sendNotificationForSensor:(Class) sensor;

//getter and setters for settings
- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting;
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value;
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent;

//used to set individual settings, returns whether the setting was accepted
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;
@end
