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

///used to set individual settings, returns whether the setting was accepted
- (BOOL) setLogin:(NSString*)user withPassword:(NSString*) password;
@end
