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


@interface CSNoiseSensor : CSSensor <AVAudioRecorderDelegate> {
	@private AVAudioRecorder* audioRecorder;
	@private NSTimeInterval sampleInterval;
	@private NSTimeInterval sampleDuration;
	@private NSTimeInterval volumeSampleInterval;
	@private NSTimer* sampleTimer;
	@private NSTimer* volumeTimer;
	
	@private double volumeSum;
	@private NSInteger nrVolumeSamples;
}

- (void) settingChanged: (NSNotification*) notification;

@property (retain) NSTimer* sampleTimer;
@property (retain) NSTimer* volumeTimer;
@end
