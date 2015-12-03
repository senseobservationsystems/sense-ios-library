//
//  CSSensorConstants.h
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/12/15.
//
//

#import <Foundation/Foundation.h>

extern NSString* const CSSorceName_iOS;

/** @name Settings */

//notifications
extern NSString* const CSsettingLoginChangedNotification;
extern NSString* const settingSynchronisationChangedNotification;
extern NSString* const CSanySettingChangedNotification;

//setting types
extern NSString* const kCSSettingTypeGeneral;
extern NSString* const kCSSettingTypeBiometric;
extern NSString* const kCSSettingTypeLocation;
extern NSString* const kCSSettingTypeSpatial;
extern NSString* const kCSSettingTypeAmbience;

//general settings
extern NSString* const kCSGeneralSettingUsername;
extern NSString* const kCSGeneralSettingPassword;
extern NSString* const kCSGeneralSettingSenseEnabled;
extern NSString* const kCSGeneralSettingUploadInterval;
extern NSString* const kCSGeneralSettingPollInterval;
extern NSString* const kCSGeneralSettingAutodetect;
extern NSString* const kCSGeneralSettingUploadToCommonSense;
extern NSString* const kCSGeneralSettingDontUploadBursts;
extern NSString* const kCSGeneralSettingBackgroundRestarthack;
extern NSString* const kCSGeneralSettingLocalStorageEncryption;
extern NSString* const kCSGeneralSettingLocalStorageEncryptionKey;
extern NSString* const kCSGeneralSettingUseStaging;

//biometric settings
extern NSString* const kCSBiometricSettingGender;
extern NSString* const kCSBiometricSettingBirthDate;
extern NSString* const kCSBiometricSettingWeight;
extern NSString* const kCSBiometricSettingHeight;
extern NSString* const kCSBiometricSettingBodyFat;
extern NSString* const kCSBiometricSettingMaxPulse;

//activity settings
extern NSString* const kCSActivitySettingDetection;
extern NSString* const kCSActivitySettingPrivacy;

//location settings
extern NSString* const kCSLocationSettingAccuracy;
extern NSString* const kCSLocationSettingMinimumDistance;
extern NSString* const kCSLocationSettingCortexAutoPausing;		/** Setting for automatically pausing location updates for two minutes after a new datapoint has come in, this might save battery life **/
extern NSString* const kCSLocationSettingAutoPausingInterval;

//spatial settings
extern NSString* const kCSSpatialSettingInterval;
extern NSString* const kCSSpatialSettingFrequency;
extern NSString* const kCSSpatialSettingNrSamples;

//ambience settings
extern NSString* const kCSAmbienceSettingInterval;
extern NSString* const kCSAmbienceSettingSampleOnlyWhenScreenLocked;


//Most settings are numbers (with SI units, i.e. seconds, meters, kg, percent etc.). Categorical values should be one of the following strings
//boolean
extern NSString* const kCSSettingYES;
extern NSString* const kCSSettingNO;

//upload interval
extern NSString* const kCSGeneralSettingUploadIntervalNightly;
extern NSString* const kCSGeneralSettingUploadIntervalWifi;
extern NSString* const kCSGeneralSettingUploadIntervalAdaptive;

//biometric
extern NSString* const kCSBiometricSettingGenderMale;
extern NSString* const kCSBiometricSettingGenderFemale;

//activity detection
extern NSString* const kCSActivitySettingDetectionDetectOnly;
extern NSString* const kCSActivitySettingDetectionIgnore;
extern NSString* const kCSActivitySettingDetectionDetectAndUpload;

//activity privacy
extern NSString* const kCSActivitySettingPrivacyPrivate;
extern NSString* const kCSActivitySettingPrivacyFriends;
extern NSString* const kCSActivitySettingPrivacyFriendsOfFriends;
extern NSString* const kCSActivitySettingPrivacyActivitiesCommunity;
extern NSString* const kCSActivitySettingPrivacyPublic;

// provider identifiers
extern NSString* const kCSLOCATION_PROVIDER;
extern NSString* const kCSSPATIAL_PROVIDER;
extern NSString* const kCSAMBIENCE_PROVIDER;
extern NSString* const kCSEnableLocationProvider;
@interface CSSensorConstants : NSObject 
@end