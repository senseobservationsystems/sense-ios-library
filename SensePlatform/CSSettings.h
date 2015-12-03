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




/**
 Each individual setting is stored in a CSSetting object with a name and a value.
 */
@interface CSSetting : NSObject
{
	NSString* name;
	NSString* value;
}

/**
 The name of a certain setting. All names are stored and documented as constants in CSSettings.h.
 */
@property (copy) NSString* name;

/**
 The value of a setting is always stored as a string. It can be used for storing number encoded values as strings. There are two special values 

	kCSSettingYES and kCSSettingNO
 
 These are strings that represent boolean values.
 */
@property (copy) NSString* value;

@end

/**
 This singleton is used to control the settings of the sense platform. Using this class all available settings can be set.
 
 Each setting is stored in a CSSetting object that contains a name and value (see above). All the potential settings are listed here, as well as their potential values. Several methods for changing and obtaining the settings are available and documented below. 
 
 
 ___Setting types___
 
 Each setting also has a type, which makes it easier to group them and listen only to setting changes of a specific type. Currently, 5 different types have been defined:
 
 - `kCSSettingTypeGeneral`: This a placeholder for all settings that don't belong to any of the other types.
 - `kCSSettingTypeBiometric`: User specific settings like age, height, date of birth, and gender.
 - `kCSSettingTypeLocation`: All settings related to the location sensor, visits sensor, and the location provider, including sampling settings and accuracy.
 - `kCSSettingTypeSpatial`: All settings related to the spatial settings and spatial data provider. This includes the accelerometer sensors and motion features.
 - `kCSSettingTypeAmbience`: All settings related to the ambience sensors. Right now this is only the noise sensor (microphone data).
 
 
___General settings___
 
 - `kCSGeneralSettingUsername`<br>
	The username of the user is stored as a setting for persistency. This is handled in CSSensePlatform login, logout, and register methods so doesn't need to be set manually. Any valid string value is accepted.
 - `kCSGeneralSettingPassword`<br> The password of the uer is stored as a setting for persistency. This is handled in CSSensePlatform login, logout, and register methods so it doesn't to be set manually. Note that when encryption is enabled, the settings including the password are also encrypted. The password itself is stored as an MD5 hashed String.
 - `kCSGeneralSettingSenseEnabled`<br> This is a shorthand for disabling all sensors and uploads to commonsense. When enabled, the old settings are restored, enabling all the sensors that have been individually enabled. Values are `kCSSettingYes` or `kCSSettingNo`. Enabled by default.
 - `kCSGeneralSettingUploadInterval`<br> The interval is seconds specifies the time between consecutive uploads to commonsense. Value can be specified in seconds using a string. There are also three special settings available but they are not implement right now so they should not be used. 1800 seconds (30 minutes) by default.
 - `kCSGeneralSettingPollInterval`<br> This setting is not being used currently. Polling intervals are specified per sensor.
 - `kCSGeneralSettingAutodetect`<br> This setting is not being used.
 - `kCSGeneralSettingUploadToCommonSense`<br> When enabled, data will be uploaded to commonsense according to a specified interval. Values are `kCSSettingYes` or `kCSSettingNo`. Enabled by default.
 - `kCSGeneralSettingDontUploadBursts`<br>This specifies whether or not data from burst sensors should be uploaded to commonsense. Data in burst sensors contains all data that is often sampled at a high frequency. It can be used effectively for specific algorithms to detect behavior of the user for instance, but uploading it might take time, battery, and data usage. For improved battery usage, we advice not to upload burst data but only use it locally. Values are `kCSSettingYes` or `kCSSettingNo`. Enabled by default.
 - `kCSGeneralSettingBackgroundRestarthack`<br>This settings enables the running of sense library in the background. For this, it enables the CSLocationProvider. If one has already enabled the location sensor, or any sensor that uses the location provider there is no need for enabling this setting because the individual sensors that make use of the location provider also can enable it. For more details, see the Background services document. Enabled by default to be able to run in the background.
 - `kCSGeneralSettingLocalStorageEncryption`<br>This setting enables or disables encryption of local data (settings file and sensordata database). Note that encryption will decrease performance slightly. Values are `kCSSettingYes` or `kCSSettingNo`. Disabled by default.
 - `kCSGeneralSettingLocalStorageEncryptionKey` Key used for encryption.
 - `kCSGeneralSettingUseStaging` This setting enables or disables the use of the staging server. It changes all URLs for remote communication to either the commonsense live API or the commonsense staging API. Values are `kCSSettingYes` or `kCSSettingNo`. Disabled by default.
 
___Biometric settings___

 These are placeholders not currently being used actively. We discourage usage of them for now.
 
 - `kCSBiometricSettingGender`
 - `kCSBiometricSettingBirthDate`
 - `kCSBiometricSettingWeight`
 - `kCSBiometricSettingHeight`
 - `kCSBiometricSettingBodyFat`
 - `kCSBiometricSettingMaxPulse`
 
 
___Activity settings___
 
 These are placeholder not currently being used actively. We discourage usage of them for now.
 
 - `kCSActivitySettingDetection`
 - `kCSActivitySettingPrivacy`
 
___Location settings___
 
 - `kCSLocationSettingAccuracy`<br> Accuracy with which iOS will detect location data points. Lower values will provide higher accuracy but will also use more battery. Apple generally distinguishes three levels: GPS, WiFi, Cell tower. GPS is the most accurate (< 1 meter) but uses a lot of battery power. Wifi is accurate at around ~100 meters and uses less battery. Cell tower is accurate at about ~2 km and uses the least amount of battery. Setting is specified in meters (as a String). The default value is set to 100 meters.
 - `kCSLocationSettingMinimumDistance`<br> Minimum distance used before getting a location update. When not specified it updates whenever iOS deems it relevant to update, this is recommended. Specified in meters. Uses the standard iOS functionality. Not set by default.
 - `kCSLocationSettingCortexAutoPausing`<br>	Setting for automatically pausing location updates for three minutes after a new datapoint has come in, this might save battery life. Values are `kCSSettingYes` or `kCSSettingNo`. Disabled by default.

___Spatial settings___
 
 - `kCSSpatialSettingInterval`<br> Interval between sampling spatial (motion) data. Specified in seconds, by default set to 60 seconds.
 - `kCSSpatialSettingFrequency`<br> Sample frequency of the motion data sampling. Specified in Herz. By default set to 50 Hz. Note that this is limited by hardware potential.
 - `kCSSpatialSettingNrSamples`<br> Number of samples to collect for each sampling cycle. Specified in numbers of samples. By default set to 150 samples, this means 3 seconds of sampled data when using the standard of 50 Hz as sampling frequency.

___Ambience settings___

  - `kCSAmbienceSettingInterval`<br> Interval between sampling ambience (currently only noise) data. Specified in seconds, by default set to 60 seconds.
  - `kCSAmbienceSettingSampleOnlyWhenScreenLocked`<br> Enabling or disabling sampling when the screen is on. When the screen is on and mircrophone is being sampled iOS shows a red bar at the top of the screen. This might scare users. A solution could be to only sample ambience (noise) data when the screen is turned off. When this setting is turned on, that is what will happen. Note that when the screen gets turned on at the moment the sampling has already started the sampling will be finished (and hence there is a small chance the red bar will be seen by the user). Disabled by default.


___Persistency___
 
Settings are by default persisted in a local storage file to make sure that when the app is killed settings are restored when restarted. The settings in the file are loaded whenever CSSettings.h is instantiated (if it exists). The settings file can be encrypted by setting the `kCSGeneralSettingLocalStorageEncryption` to Yes. When it does not exist a new file is created with the default settings.
 
___Default settings___
 
 - Upload interval to commonsense: 1800 seconds (`kCSGeneralSettingUploadInterval`)
 - Enabling upload to commonsense: Yes (`kCSGeneralSettingUploadToCommonSense`)
 - Enabling sensors that have been requested: Yes (`kCSGeneralSettingSenseEnabled`)
 - Enabling encryption on the local storage: No (`kCSGeneralSettingLocalStorageEncryption`)
 - Using the staging server: No (`kCSGeneralSettingUseStaging`)
 - Sample ambience (noise) only when screen is locked: No (`kCSAmbienceSettingSampleOnlyWhenScreenLocked`)
 - Sample interval for ambience (noise) sensors: 60 seconds (`kCSAmbienceSettingInterval`)
 - Location sampling accuracy: 100 meters (`kCSLocationSettingAccuracy`)
 - Automatically pausing the location sensing for 3 minutes between updates: No (`kCSLocationSettingCortexAutoPausing`)
 - Interval of sampling spatial (motion) sensors: 60 seconds (`kCSSpatialSettingInterval`)
 - Sample frequency when sampling spatial (motion) sensors: 50 Hz (`kCSSpatialSettingFrequency`)
 - Number of samples to sample every cycle: 150 samples (`kCSSpatialSettingNrSamples`)


___Listening to changes___
 
When a setting is changed a notification is broadcasted to all listeners. To listen to sensor enabling or disabling, a class can declare
 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enabledChanged:) name:[CSSettings enabledChangedNotificationNameForSensor:[MySensor name]] object:nil];
 
Or to listen to other specific sensor notifications
 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enabledChanged:) name:[CSSettings settingChangedNotificationNameForSensor:[MySensor name]] object:nil];

To listen to notifications of a specific type
 
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enabledChanged:) name:[CSSettings settingChangedNotificationNameForType:[MyObject type]] object:nil];
 
 
 
 ___Warning___
 
 Note that some of the functionality of this class should no longer be used directly by the developer but instead can be used through CSSensorRequirements.h, which provides a way of dealing with potentially conflicting settings. Especially the enabling/disabling of sensors or the setting of specific parameters for sensors should be done there. See CSSensorRequirements.h for more details.
 
 
 
 ___Warning___
 
Settings are not stored specifically for each user. Hence when another user would start using the same install of the app without removing it first, it would be using the same settings. Login/Register and Logout do clear the credential settings though.
 
 */
@interface CSSettings : NSObject {

}


/** @name Class methods */

/**
 Provides the singleton object for this class
 */
+ (CSSettings*) sharedSettings;

/** Returns the name of enable notifications for the specified sensor. This can be used for an object to instantiate an observer. 
 @param sensor The of the sensor for which the enable notifications should be observed.
 @return The name of the enable notifications for the specified sensor.
 */
+ (NSString*) enabledChangedNotificationNameForSensor:(NSString*) sensor;
 
/** Returns the name of setting changed notifications for a specified type of settings. This can be used for an object to instantiate an observer.
 @param type The type of sensor changes that one wants to listen to. This can be either kCSSettingTypeGeneral, kCSSettingTypeGeneral, kCSSettingTypeLocation,kCSSettingTypeSpatial,kCSSettingTypeAmbience. See the overview of this class for more info.
 @return The name of the enable notifications for the specified type
 */
+ (NSString*) settingChangedNotificationNameForType:(NSString*) type;

/** Returns the name of the permission granted notification for a specific provider.
 @param provider The provider for which the permission was granted.
 @return The name of the permission granted notification.
 */
+ (NSString*) permissionGrantedForProvider: (NSString*) provider;

/** Returns the name of the permission denied notification for a specific provider.
 @param provider The provider for which the permission was granted.
 @return The name of the permission denied notification.
 */
+ (NSString*) permissionDeniedForProvider: (NSString*) provider;


/** @name Setting settings (pun intended) */

/** 
 Enable/disable the specified sensor, setting is persistent.
 
 This notifies observers.
 
 @param sensor Name of the sensor to enable or disable
 @param enable True if it should be enabled, false if sensor should be disabled
 @return New value of the sensor's isEnabled method.
*/
 - (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable;


/** Enable/disable the specified sensor, specifying whether or not the setting should be persistent.

 This notifies observers.
 
 @param enable Wether to enable or disable the sensor
 @param sensor Name of the sensor
 @param persistent Whether this setting is persistent
 @return New value of the sensor's isEnabled method.
 */
- (BOOL) setSensor:(NSString*) sensor enabled:(BOOL) enable persistent:(BOOL) persistent;



/** Set the value of the specified setting, the setting is persistent.
 
 This notifies observers.
 
 @param type The setting type
 @param setting The specific setting for the type
 @param value The value of to set the setting to
 @return Whether or not updating the setting was successful.
 */
- (BOOL) setSettingType: (NSString*) type setting:(NSString*) setting value:(NSString*) value;


/** Set the value of the specified setting

 This notifies observers.
 
 @param type The setting type. See the overview above for the available types.
 @param setting The specific setting for the type
 @param value The value of to set the setting to
 @param persistent Whether the setting should be persistent
 @return Whether or not updating the setting was successful.
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



/** @name Getting settings */

/**
 Returns wether the specified sensor is enabled
 @param sensor Name of the sensor to check
 @return Whether or not the specified sensor is enabled
 */
- (BOOL) isSensorEnabled:(NSString*) sensor;

/** Send notifications for a specific sensor. Notifies all observers about this sensor. 
 @param sensor Name of the sensor
 */
- (void) sendNotificationForSensor:(NSString*) sensor;

/** Get the value of the specified setting
 * @param type the setting type
 * @param setting the specific setting for the type
 * @return the value of the setting
 */
- (NSString*) getSettingType: (NSString*) type setting:(NSString*) setting;

/** @name Reset */

/** 
 Reset the settings to defaults.
 
 The default settings are:
 
 - Upload interval to commonsense: 1800 seconds (`kCSGeneralSettingUploadInterval`)
 - Enabling upload to commonsense: Yes (`kCSGeneralSettingUploadToCommonSense`)
 - Enabling sensors that have been requested: Yes (`kCSGeneralSettingSenseEnabled`)
 - Enabling encryption on the local storage: No (`kCSGeneralSettingLocalStorageEncryption`)
 - Using the staging server: No (`kCSGeneralSettingUseStaging`)
 - Sample ambience (noise) only when screen is locked: No (`kCSAmbienceSettingSampleOnlyWhenScreenLocked`)
 - Sample interval for ambience (noise) sensors: 60 seconds (`kCSAmbienceSettingInterval`)
 - Location sampling accuracy: 100 meters (`kCSLocationSettingAccuracy`)
 - Automatically pausing the location sensing for 3 minutes between updates: No (`kCSLocationSettingCortexAutoPausing`)
 - Interval of sampling spatial (motion) sensors: 60 seconds (`kCSSpatialSettingInterval`)
 - Sample frequency when sampling spatial (motion) sensors: 50 Hz (`kCSSpatialSettingFrequency`)
 - Number of samples to sample every cycle: 150 samples (`kCSSpatialSettingNrSamples`)
 */
- (void) resetToDefaults;
@end
