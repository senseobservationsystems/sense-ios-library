//
//  CSSensorConstants.m
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 01/12/15.
//
//

#import <Foundation/Foundation.h>
#import "CSSensorConstants.h"

NSString* const CSSorceName_iOS = @"sense-library";
//notifications
NSString* const kCSNewSensorDataNotification = @"CSNewSensorDataNotification";
NSString* const kCSNewMotionDataNotification = @"CSNewMotionDataNotification";
NSString* const CSsettingLoginChangedNotification = @"CSsettingLoginChangedNotification";
NSString* const CSanySettingChangedNotification = @"CSanySettingChangedNotification";

//credentials
NSString* const kCSCredentialsUserId = @"CSCredentialsUserId";
NSString* const kCSCredentialsAppKey = @"CSCredentialsAppKey";
NSString* const kCSCredentialsSessionId = @"CSCredentialsSessionId";

//setting types
NSString* const kCSSettingTypeGeneral = @"general";
NSString* const kCSSettingTypeBiometric = @"biometric";
NSString* const kCSSettingTypeActivity = @"activity";
NSString* const kCSSettingTypeLocation = @"position";
NSString* const kCSSettingTypeSpatial = @"spatial";
NSString* const kCSSettingTypeAmbience = @"ambience";

//general settings keys
NSString* const kCSGeneralSettingSenseEnabled = @"senseEnabled";
NSString* const kCSGeneralSettingUsername = @"username";
NSString* const kCSGeneralSettingPassword = @"password";
NSString* const kCSGeneralSettingUploadInterval = @"synchronisationRate";
NSString* const kCSGeneralSettingPollInterval = @"pollRate";
NSString* const kCSGeneralSettingAutodetect = @"auto detect";
NSString* const kCSGeneralSettingUploadToCommonSense = @"upload to CommonSense";
NSString* const kCSGeneralSettingDontUploadBursts = @"dontUploadBurstData";
NSString* const kCSGeneralSettingBackgroundRestarthack = @"enableBackgroundRestarthack";
NSString* const kCSGeneralSettingLocalStorageEncryption = @"enableLocalStorageEncryption";
NSString* const kCSGeneralSettingLocalStorageEncryptionKey = @"localStorageEncryptionKey";
NSString* const kCSGeneralSettingUseStaging = @"useStaging";

//biometric settings
NSString* const kCSBiometricSettingGender = @"gender";
NSString* const kCSBiometricSettingBirthDate = @"birth date";
NSString* const kCSBiometricSettingWeight = @"weight";
NSString* const kCSBiometricSettingHeight = @"height";
NSString* const kCSBiometricSettingBodyFat = @"body fat";
NSString* const kCSBiometricSettingMaxPulse = @"max pulse";

//activity settings
NSString* const kCSActivitySettingDetection = @"detection";
NSString* const kCSActivitySettingPrivacy = @"privacy";

//location settings keys
NSString* const kCSLocationSettingAccuracy = @"accuracy";
NSString* const kCSLocationSettingMinimumDistance = @"minimumDistance";
NSString* const kCSLocationSettingCortexAutoPausing = @"autoPausing";
NSString* const kCSLocationSettingAutoPausingInterval = @"autoPausingInterval";

//spatial settings
NSString* const kCSSpatialSettingInterval = @"pollInterval";
NSString* const kCSSpatialSettingFrequency = @"frequency";
NSString* const kCSSpatialSettingNrSamples = @"number of samples";

//ambiance settings
NSString* const kCSAmbienceSettingInterval = @"pollInterval";
NSString* const kCSAmbienceSettingSampleOnlyWhenScreenLocked = @"sampleOnlyWhenScreenLocked";

//categorical values
NSString* const kCSSettingYES = @"1";
NSString* const kCSSettingNO = @"0";

NSString* const kCSGeneralSettingUploadIntervalNightly = @"nightly";
NSString* const kCSGeneralSettingUploadIntervalWifi = @"wifi";
NSString* const kCSGeneralSettingUploadIntervalAdaptive = @"adaptive";

//biometric
NSString* const kCSBiometricSettingGenderMale = @"male";
NSString* const kCSBiometricSettingGenderFemale = @"female";

//activity detection
NSString* const kCSActivitySettingDetectionDetectOnly = @"detect only";
NSString* const kCSActivitySettingDetectionIgnore = @"ignore";
NSString* const kCSActivitySettingDetectionDetectAndUpload = @"detect and upload";

//activity privacy
NSString* const kCSActivitySettingPrivacyPrivate = @"private";
NSString* const kCSActivitySettingPrivacyFriends = @"friends";
NSString* const kCSActivitySettingPrivacyFriendsOfFriends = @"friends of friends";
NSString* const kCSActivitySettingPrivacyActivitiesCommunity = @"activities community";
NSString* const kCSActivitySettingPrivacyPublic = @"public";

// provider identifiers
NSString* const kCSLOCATION_PROVIDER = @"location_provider";
NSString* const kCSSPATIAL_PROVIDER = @"spatial_provider";
NSString* const kCSAMBIENCE_PROVIDER = @"ambience_provider";
NSString* const kCSEnableLocationProvider = @"location_provider_on";

@implementation CSSensorConstants{
    
    
}
@end
