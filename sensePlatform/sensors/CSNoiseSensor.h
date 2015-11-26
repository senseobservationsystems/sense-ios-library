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
#import <AVFoundation/AVAudioRecorder.h>
#import "CSSensor.h"

/**
 Sensor that stores noise data collected from the phone's microphone. It does not store the actual audio but processes it an amount of decibel to describe the amount of ambient noise. Note that right now this sensor does its own data collection. 
 
 ___Ambience settings___
 
 - <code>kCSAmbienceSettingInterval</code><br> Interval between sampling ambience (currently only noise) data. Specified in seconds, by default set to 60 seconds.
 - <code>kCSAmbienceSettingSampleOnlyWhenScreenLocked</code><br> Enabling or disabling sampling when the screen is on. When the screen is on and mircrophone is being sampled iOS shows a red bar at the top of the screen. This might scare users. A solution could be to only sample ambience (noise) data when the screen is turned off. When this setting is turned on, that is what will happen. Note that when the screen gets turned on at the moment the sampling has already started the sampling will be finished (and hence there is a small chance the red bar will be seen by the user). Disabled by default.

 ___JSON output value format___
 	
	"value": FLOAT;
 
 */
@interface CSNoiseSensor : CSSensor <AVAudioRecorderDelegate> {
}

- (void) settingChanged: (NSNotification*) notification;
@end
