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

#import "CSNoiseSensor.h"
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>
#import <CoreMedia/CMBlockBuffer.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioServices.h>
#import "CSSettings.h"
#import "CSDataStore.h"
#import "Formatting.h"

//Declare private methods using empty category
@interface CSNoiseSensor()
- (void) startRecording;
- (void) scheduleRecording;
@end

@implementation CSNoiseSensor {
    AVAudioRecorder* audioRecorder;
    NSTimeInterval sampleInterval;
    NSTimeInterval sampleDuration;
    NSTimeInterval volumeSampleInterval;
	
    double volumeSum;
    NSInteger nrVolumeSamples;
    
    dispatch_queue_t recordQueue;
    dispatch_queue_t volumeTimerQueue;
    dispatch_source_t volumeTimer;
    NSObject* volumeTimerLock;
}

- (NSString*) name {return kCSSENSOR_NOISE;}
- (NSString*) displayName {return @"noise";}
- (NSString*) deviceType {return [self name];}
+ (BOOL) isAvailable {return YES;}


- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self displayName], @"display_name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"float", @"data_type",
			nil];
}

- (id) init {
	self = [super init];
	if (self) {
		
		//define audio category to allow mixing
		NSError *setCategoryError = nil;
		[[AVAudioSession sharedInstance]
		 setCategory: AVAudioSessionCategoryPlayAndRecord
		 error: &setCategoryError];
		OSStatus propertySetError = 0;
		UInt32 value = true;
		NSError* error;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];

		propertySetError = AudioSessionSetProperty (
													kAudioSessionProperty_OverrideCategoryMixWithOthers,
													sizeof (value),
													&value
													);
        value = kAudioSessionOverrideAudioRoute_Speaker;
        propertySetError = AudioSessionSetProperty (
                                                    kAudioSessionProperty_OverrideAudioRoute,
													sizeof (value),
													&value
													);
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
		//set recording file
		NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
		NSString* path = [rootPath stringByAppendingPathComponent:@"recording.wav"];
		NSURL* recording = [NSURL fileURLWithPath: path];
        
		
		/*
		NSDictionary* recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
										[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
										[NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
										nil];
		 */

		audioRecorder = [[AVAudioRecorder alloc] initWithURL:recording settings:nil error:&error];
		if (nil == audioRecorder) {
			NSLog(@"Recorder could not be initialised. Error: %@", error);
		}
		audioRecorder.delegate = self;
		audioRecorder.meteringEnabled = YES;
        
        //register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeAmbience] object:nil];
        sampleInterval = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval] doubleValue];
        sampleDuration = 2;
		volumeSampleInterval = 0.2;
        
        recordQueue = dispatch_queue_create("com.sense.platform.noiseRecord", NULL);
        volumeTimerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        volumeTimerLock = [[NSObject alloc] init];
	}
	return self;
}

- (void) scheduleRecording {
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, sampleInterval * NSEC_PER_SEC);
    dispatch_after(popTime, recordQueue, ^(void){
        @autoreleasepool {

        [self startRecording];
        }
    });
}

- (void) startRecording {
    UInt32 audioIsPlaying = 0;
    UInt32 size = sizeof(audioIsPlaying);
    AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &audioIsPlaying);
    if (audioIsPlaying) {
        // Recording can interfere with others apps playing/recording. Don't record when another app is playing should improve user experience,
        // at the cost of some missing data.
        [self scheduleRecording];
        return;
    }

    
	audioRecorder.delegate = self;
	BOOL started = [audioRecorder recordForDuration:sampleDuration];
	NSLog(@"recorder %@", started? @"started":@"failed to start");
	if (NO == started || audioRecorder.isRecording == NO) {
		//try again later
		[self scheduleRecording];
		return;
	}
	volumeSum = 0;
	nrVolumeSamples = 0;
    
    //start a timer to sample volume
    @synchronized(volumeTimerLock) {
        if (volumeTimer) {
            dispatch_source_cancel(volumeTimer);
            dispatch_release(volumeTimer);
        }
        uint64_t leeway = volumeSampleInterval * 0.05 * NSEC_PER_SEC; //5% leeway
        volumeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, volumeTimerQueue);
        dispatch_source_set_event_handler(volumeTimer, ^{
            [audioRecorder updateMeters];
            volumeSum +=  pow(10, [audioRecorder averagePowerForChannel:0] / 20);
            ++nrVolumeSamples;
        });
        dispatch_source_set_timer(volumeTimer, dispatch_walltime(NULL, volumeSampleInterval * NSEC_PER_SEC), volumeSampleInterval * NSEC_PER_SEC, leeway);
        dispatch_resume(volumeTimer);
    }
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	if (enable == isEnabled) return;
	
	NSLog(@"Enabling noise sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	isEnabled = enable;
	if (enable) {
		if (NO==audioRecorder.recording) {
			[self startRecording];
		}
	} else {
        @synchronized(volumeTimerLock) {
            if (volumeTimer) {
                dispatch_source_cancel(volumeTimer);
                dispatch_release(volumeTimer);
                volumeTimer = NULL;
            }
        }
		audioRecorder.delegate = nil;
		[audioRecorder stop];
	}
    isEnabled = enable;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)didSucceed {
	NSLog(@"recorder stopped");

    @synchronized(volumeTimerLock) {
        if (volumeTimer) {
            dispatch_source_cancel(volumeTimer);
            dispatch_release(volumeTimer);
            volumeTimer = NULL;
        }
    }

	if (didSucceed && nrVolumeSamples > 0)	{
		//take timestamp
		double timestamp = [[NSDate date] timeIntervalSince1970];

        double level = 20 * log10(volumeSum / nrVolumeSamples);
 
		//TODO: save file...
		[recorder deleteRecording];
	
		NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
											CSroundedNumber(level, 1), @"value",
											CSroundedNumber(timestamp, 3), @"date",
											nil];
	
		[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
	} else {
		NSLog(@"recorder finished unsuccesfully");
	}

	if (isEnabled) {
		[self scheduleRecording];
	}
}

-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
	NSLog(@"Noise sensor interrupted.");
    [recorder stop];
	[recorder deleteRecording];
    [self scheduleRecording];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags {
}


- (void) settingChanged: (NSNotification*) notification {
	@try {
		CSSetting* setting = notification.object;
		NSLog(@"noise: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:kCSAmbienceSettingInterval]) {
			sampleInterval = [setting.value doubleValue];
		}
	}
	@catch (NSException * e) {
		NSLog(@"spatial provider: Exception thrown while changing setting: %@", e);
	}
	
}

- (void) dealloc {
	NSLog(@"Deallocating noise sensor");
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.isEnabled = NO;
    [NSThread sleepForTimeInterval: 0.1];
}

@end
