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

#import <Foundation/Foundation.h>

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

//spatial settings
extern NSString* const kCSSpatialSettingInterval;
extern NSString* const kCSSpatialSettingFrequency;
extern NSString* const kCSSpatialSettingNrSamples;

//ambience settings
extern NSString* const kCSAmbienceSettingInterval;


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


@interface CSSetting : NSObject
{
	NSString* name;
	NSString* value;
}

@property (copy) NSString* name;
@property (copy) NSString* value;

@end

/** This singleton is used to control the settings of the sense platform. Using this class sensors can be enabled/disabled and specific settings be set.
 */
@interface CSSettings : NSObject {

}
+ (CSSettings*) sharedSettings;

///Returns the name of enable notifications for the specified sensor
+ (NSString*) enabledChangedNotificationNameForSensor:(NSString*) sensor;
//////Returns the name of the notification send when a setting of the specified type changes
+ (NSString*) settingChangedNotificationNameForType:(NSString*) type;

///Enable/disable the specified sensor, setting is persistent
- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable;
/** Enable/disable the specified sensor
 * @param enable wether to enable or disable the sensor
 * @param persistent whether this setting is persistent
 */
- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable persistent:(BOOL) persistent;
///Returns wether the specified sensor is enabled
- (BOOL) isSensorEnabled:(NSString*) sensor;

//send notifications to a specific sensor 
- (void) sendNotificationForSensor:(NSString*) sensor;

/** Get the value of the specified setting
 * @param type the setting type
 * @param setting the specific setting for the type
 * @returns the value of the setting
 */
- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting;
/** Set the value of the specified setting, the setting is persistent
 * @param type the setting type
 * @param setting the specific setting for the type
 * @param value the value of to set the setting to
 */
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value;
/** Set the value of the specified setting
 * @param type the setting type
 * @param setting the specific setting for the type
 * @param value the value of to set the setting to
 * @param persistent whether the setting should be persistent
 */
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value persistent:(BOOL)persistent;

/** Login with user and password
 * @param user the username
 * @param password the plain password
 */
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;

/** Login with user and a hash of the password
 * @param user the username
 * @param passwordHash the hash of the password
 */
- (BOOL) setLogin:(NSString*)user withPasswordHash:(NSString*) passwordHash;
@end
