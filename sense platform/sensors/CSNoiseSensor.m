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

#define AVLinearPCMIsNonInterleavedKey AVLinearPCMIsNonInterleaved
#define SCALE_FACTOR 32767


int tesing = 0;

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
    
    //---------------------------------
    double lowPassResults;
    NSURL* recording;
    int numberOfPackets;
    BOOL interruptedOnRecording;
    BOOL sampleOnlyWhenScreenLocked;
    BOOL screenIsOn;
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
        
        //BOOL screenSensor = [[CSSettings sharedSettings] isSensorEnabled:kCSSENSOR_SCREEN_STATE];
        //NSLog(@"******&*&*&*&*&**&*&&* SCREEN_SENSOR: %d", screenSensor);
        //if (screenSensor == YES) {
        //    NSLog(@"****************** SCREEN SENSOR IS ON");
        //}
        
        //subscribe to sensor data
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewData:) name:kCSNewSensorDataNotification object:nil];
		
		//define audio category to allow mixing. Since ios7 this doesn't work any more. If we do that we fail to record in the background
		/* NSError *setCategoryError = nil;
		[[AVAudioSession sharedInstance]
		 setCategory: AVAudioSessionCategoryPlayAndRecord
		 error: &setCategoryError];
		OSStatus propertySetError = 0;
		UInt32 value = 0;
		NSError* error;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];

		propertySetError = AudioSessionSetProperty (
													kAudioSessionProperty_OverrideCategoryMixWithOthers,
													sizeof (value),
													&value
													); */
        /*
        value = kAudioSessionOverrideAudioRoute_Speaker;
        propertySetError = AudioSessionSetProperty (
                                                    kAudioSessionProperty_OverrideAudioRoute,
													sizeof (value),
													&value
													);
         */
        //[[AVAudioSession sharedInstance] setActive:YES error:&error];
		//set recording file
		/*NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
		NSString* path = [rootPath stringByAppendingPathComponent:@"recording.wav"];
		NSURL* recording = [NSURL fileURLWithPath: path];*/
        
		
		/*
		NSDictionary* recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithInt:kAudioFormatAppleLossless], AVFormatIDKey,
										[NSNumber numberWithFloat:44100.0], AVSampleRateKey,
										[NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
										nil];
		 */

		/*audioRecorder = [[AVAudioRecorder alloc] initWithURL:recording settings:nil error:&error];
		if (nil == audioRecorder) {
			NSLog(@"Recorder could not be initialised. Error: %@", error);
		}
		audioRecorder.delegate = self;
		audioRecorder.meteringEnabled = YES;*/
        
        //register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeAmbience] object:nil];
        
        
        sampleInterval = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval] doubleValue];
        //sampleInterval = 6; // seconds
        sampleDuration = 10; // seconds
		volumeSampleInterval = 0.2;
        

        
        recordQueue = dispatch_queue_create("com.sense.platform.noiseRecord", NULL);
        volumeTimerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        volumeTimerLock = [[NSObject alloc] init];
        
        // configuration of the audio session
        // call audioSessionConfiguration
        [self audioSessionConfiguration];
        // call audioRecorderConfiguration
        [self audioRecorderConfiguration];
        numberOfPackets = 0;
        screenIsOn = YES;
	}
	return self;
}

/** Configure the audio session of the app
 *
 */
- (void) audioSessionConfiguration
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *activationError = nil;
    NSError *categoryError = nil;
    AVAudioSessionPortDescription *appPortInput = nil;
    // audio session category
    NSString *appAudioSessionCategory = AVAudioSessionCategoryPlayAndRecord;
    NSError *theError = nil;
    BOOL result = YES;
    
    // Sets audio session category and mode=default
    if (![session setCategory:appAudioSessionCategory withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDefaultToSpeaker error:&categoryError]) {
        NSLog(@"Audio session can't set category and mode. Error: %@", categoryError);
    }
    // activate session
    if (![session setActive:YES error:&activationError]) {
        NSLog(@"Audio session can't be actived. Error: %@", activationError);
    }
    
    /* Availabe inputs */
    NSArray *deviceInputs = [session availableInputs];
    for (AVAudioSessionPortDescription *input in deviceInputs) {
        // set as an input the build-in microphone
        if ([input.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {
            appPortInput = input;
            break;
        }
    }
    
    /* Set preferred input port */
    theError = nil;
    result = [session setPreferredInput:appPortInput error:&theError];
    if (!result)
    {
        // an error occurred. Handle it!
        NSLog(@"setPreferredInput failed. Error: %@", theError);
    }
    
    // set preferred input data source
    AVAudioSessionDataSourceDescription *bottomMic = nil;
    for (AVAudioSessionDataSourceDescription *source in appPortInput.dataSources) {
        if ([source.orientation isEqualToString:AVAudioSessionOrientationBottom]) {
            bottomMic = source;
            break;
        }
    }
    
    if (bottomMic) {
        // Set a preference for the front data source.
        theError = nil;
        result = [appPortInput setPreferredDataSource:bottomMic error:&theError];
        if (!result)
        {
            // an error occurred. Handle it!
            NSLog(@"setPreferredDataSource failed. Error: %@", theError);
        }
    }
    // register interrupt notification
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionHandler:) name:AVAudioSessionInterruptionNotification object:session];
    
}

/** Initalize and configure the audio recorder
 *
 */
- (void) audioRecorderConfiguration
{
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    /* Specifies the recording file */
    NSString* path = [rootPath stringByAppendingPathComponent:@"recording.wav"];
    recording = [NSURL fileURLWithPath: path];
    NSError *error;
    
    /* Recorder settings */
    NSDictionary *recorderSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                      [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                      [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                      nil];
    /* Recorder initialization */
    audioRecorder = [[AVAudioRecorder alloc] initWithURL:recording settings:recorderSettings error:&error];
    if (audioRecorder == nil) {
        NSLog(@"Recorder could not be initialised. Error: %@", error);
    }
    else {
        audioRecorder.delegate = self;
        audioRecorder.meteringEnabled = YES;
        [audioRecorder prepareToRecord];
    }
    //[audioRecorder recordForDuration:sampleDuration];
    interruptedOnRecording = NO;
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
    NSLog(@"*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^*^ RECORDING");
    NSLog(@"$$$$$$$$$$$$$ sampleOnlyWhenScreenLocked: %d", sampleOnlyWhenScreenLocked);

    BOOL started = NO;
    
    //UInt32 audioIsPlaying = 0;
    /* This check seem to return true always on ios7. TODO: enable on ios <7?
    UInt32 size = sizeof(audioIsPlaying);
    AudioSessionGetProperty(kAudioSessionProperty_OtherAudioIsPlaying, &size, &audioIsPlaying);
    if (audioIsPlaying) {
        // Recording can interfere with others apps playing/recording. Don't record when another app is playing should improve user experience,
        // at the cost of some missing data.
        [self scheduleRecording];
        return;
    }*/
    //NSError* error;
    //[[AVAudioSession sharedInstance] setActive:YES error:&error];
	//audioRecorder.delegate = self;
    
    // sample continuously, independant of the state of the screen
    if (sampleOnlyWhenScreenLocked == NO) {
        started = [audioRecorder recordForDuration:sampleDuration];
    }
    // sample only when the screen is locked
    else {
        if (screenIsOn == NO) {
            started = [audioRecorder recordForDuration:sampleDuration];
        }
        else {
            [self scheduleRecording];
            return;
        }
    }
    
	//BOOL started = [audioRecorder recordForDuration:sampleDuration];
    
	//NSLog(@"recorder %@", started? @"started":@"failed to start");
	if (NO == started || audioRecorder.isRecording == NO) {
		//try again later
		[self scheduleRecording];
		return;
	}
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	if (enable == isEnabled) return;
    
    sampleOnlyWhenScreenLocked = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingSampleOnlyWhenScreenLocked] isEqualToString:kCSSettingYES];
    
    NSLog(@"$$$$$$$$$$$$$ sampleOnlyWhenScreenLocked: %d", sampleOnlyWhenScreenLocked);
	
	NSLog(@"Enabling noise sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	isEnabled = enable;
    //if (enable && sampleOnlyWhenScreenLocked == NO) {
	if (enable) {
		if (NO==audioRecorder.recording) {
			[self startRecording];
		}
	} else {
        @synchronized(volumeTimerLock) {
            if (volumeTimer) {
                dispatch_source_cancel(volumeTimer);
                volumeTimer = NULL;
            }
        }
		audioRecorder.delegate = nil;
		[audioRecorder stop];
        NSError* error;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
	}
    isEnabled = enable;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)didSucceed {

    NSLog(@"DID FINISH RECORDING ***************");
    
    /* @synchronized(volumeTimerLock) {
        if (volumeTimer) {
            dispatch_source_cancel(volumeTimer);
            volumeTimer = NULL;
        }
    }

	if (didSucceed && nrVolumeSamples > 0)	{
		//take timestamp
		double timestamp = [[NSDate date] timeIntervalSince1970];

        double level = 20 * log10(volumeSum / nrVolumeSamples);
	
		NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
											CSroundedNumber(level, 1), @"value",
											CSroundedNumber(timestamp, 3), @"date",
											nil];
	
		[dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
	} else {
		NSLog(@"recorder finished unsuccesfully");
	} */
    
    if (didSucceed ==TRUE) {
        // calculate the audio recording volume in dBs
        // call computeAudioVolume
        [self computeAudioVolume];
        NSLog(@"recorder finished succesfully");
    }
    else {
        NSLog(@"recorder finished unsuccesfully");
    }

	if (isEnabled) {
		[self scheduleRecording];
	}
}

/** Stores in an array the values of the samples of the audio signal
 *  and computes the audio volume in dBs
 **/
- (void) computeAudioVolume
{
    AudioFileID recordingFile=nil;
    OSStatus result = noErr;
    // 16-bit sample
    UInt32 numberOfBytesToRead = 2;
    // 1 packet = 1 sample
    UInt32 numberOfPacketsToRead = 1;
    UInt16 sampleData = 0;
    // array with all the samples
    short int *rawSampleData;
    double sumOfRawSampleData = 0;
    double avgOfRawSampleData = 0;
    double rootAvgOfRawSampleData = 0;
    double volumeOfAudioSignal = 0;
    
    UInt32 propertySize = 0;
    UInt64 packetsCount = 0;
    
    // open recording file
    NSLog(@"------------------**************** audio file: %@", recording);
    result = AudioFileOpenURL(CFBridgingRetain(recording), kAudioFileReadPermission, 0, &recordingFile);
    if (result != 0) {
        NSLog(@"Couldn't open recording file. Error: %d", (int) result);
    }
    
    // get the total number of packets
    propertySize = 0;
    result = AudioFileGetPropertyInfo(recordingFile, kAudioFilePropertyAudioDataPacketCount, &propertySize, NULL);
    if (result != noErr) {
        NSLog(@"Error: Getting property info %d\n", (int) result);
    }
    result = AudioFileGetProperty(recordingFile, kAudioFilePropertyAudioDataPacketCount, &propertySize, &packetsCount);
    if (result != noErr) {
        NSLog(@"Error: Getting property %d\n", (int)result);
    }
    else {
        NSLog(@"Number of pakcets: %llu\n", packetsCount);
    }
    numberOfPackets = (int) packetsCount;
    
    rawSampleData = (short int*) malloc(numberOfPackets * sizeof(short int));

    for (int i=0; i<(numberOfPackets); i++) {
        rawSampleData[i] = 0;
        result = AudioFileReadPacketData(recordingFile, YES, &numberOfBytesToRead, NULL, i, &numberOfPacketsToRead, &sampleData);
        if (result != noErr) {
            NSLog(@"Couldn't read audio data from recording file. Error: %d", (int) result);
        }
        // optional use of a scale factor
        //if (sampleData < 0)
        //rawSampleData[i] = sampleData + SCALE_FACTOR;
        rawSampleData[i] = sampleData;
        sumOfRawSampleData = sumOfRawSampleData + (rawSampleData[i] * rawSampleData[i]);
    }
    
    avgOfRawSampleData = sumOfRawSampleData / numberOfPackets;
    rootAvgOfRawSampleData = sqrt(avgOfRawSampleData);
    volumeOfAudioSignal = 10 * (log10(avgOfRawSampleData));
    NSLog(@"---------- Audio recording volume(dB): %f ----------", volumeOfAudioSignal);
    
    //take timestamp
    double timestamp = [[NSDate date] timeIntervalSince1970];
    
    double level = volumeOfAudioSignal;
	
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(level, 1), @"value",
                                        CSroundedNumber(timestamp, 3), @"date",
                                        nil];
	
    [dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
    
    // Total duration of recording
    propertySize = 0;
    Float64 duration = 0;
    result = AudioFileGetPropertyInfo(recordingFile, kAudioFilePropertyEstimatedDuration, &propertySize, NULL);
    if (result != noErr) {
        NSLog(@"Error: Getting property info %d\n", (int) result);
    }
    result = AudioFileGetProperty(recordingFile, kAudioFilePropertyEstimatedDuration, &propertySize, &duration);
    if (result != noErr) {
        NSLog(@"Error: Getting property %d\n", (int)result);
    }
    else {
        NSLog(@"---------- Audio recording duration: %f ----------", (Float64) duration);
    }
    
    free(rawSampleData);
    
    // close audio file
    result = AudioFileClose(recordingFile);
    if (result != 0) {
        NSLog(@"Error: Closing audio file %d\n", (int) result);
    }
}


-(void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
	NSLog(@"Noise sensor interrupted.");
    [recorder stop];
    [self scheduleRecording];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags {
    [self scheduleRecording];
}


- (void) settingChanged: (NSNotification*) notification {
	@try {
		CSSetting* setting = notification.object;
		NSLog(@"noise: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:kCSAmbienceSettingInterval]) {
			sampleInterval = [setting.value doubleValue];
		} else if ([setting.name isEqualToString:kCSAmbienceSettingSampleOnlyWhenScreenLocked]) {
            sampleOnlyWhenScreenLocked = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingSampleOnlyWhenScreenLocked] isEqualToString:kCSSettingYES];
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

- (void) onNewData:(NSNotification*)notification {
    NSString* sensor = notification.object;
    if ([sensor isEqualToString:@"screen activity"]) {
        // if receive dispaly event and the sampleonly flag is no do nothing otherwise call schedule but
        // if you record stop
        NSString* json = [notification.userInfo valueForKey:@"value"];
        NSString *screenState = [json valueForKey:@"screen"];
        NSLog(@"SCREENNNNNNNNNNNNNNNNNNNNNNNNNNN");
        NSLog(@"SCREEN STATE: %@",  screenState);
        
        // keep track of the state of the screen
        if ([screenState isEqualToString:@"off"])
            screenIsOn = NO;
        else {
            screenIsOn = YES;
            if ([audioRecorder isRecording] == YES) {
                NSLog(@"RECORDINGGGGGGGGGGGGGG");
                [audioRecorder stop];
            }
            //[self audioRecorderBeginInterruption:audioRecorder];
            //[[AVAudioSession sharedInstance] setActive:NO error:nil];
        }
        
        // screen on
        /* if ([screenState isEqualToString:@"on"]) {
            if ([audioRecorder isRecording] == TRUE) {
                [audioRecorder stop];
            }
        }
        // screen off
        else {
            
        }
        
        if (sampleOnlyWhenScreenLocked == FALSE) {
            
        }
        if (sampleOnlyWhenScreenLocked == TRUE) {
            //[self startRecording];
            //[self scheduleRecording];
        } */
    }
    /* NSString* sensor = notification.object;
    if ([sensor isEqualToString:@"step counter"]) {
        NSString* json = [notification.userInfo valueForKey:@"value"];
        NSDate* date = [NSDate dateWithTimeIntervalSince1970:[[notification.userInfo valueForKey:@"date"] doubleValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                NSString* entry = [NSString stringWithFormat:@"%@: %@", [dateFormatter stringFromDate:date], json];
                [fallLog insertObject:entry atIndex:0];
                while ([fallLog count] > MAX_ENTRIES) {
                    [fallLog removeLastObject];
                }
                
                [self.logText setText:[fallLog componentsJoinedByString:@"\n"]];
            }
        });
    } */
}

@end
