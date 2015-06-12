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
#import <AVFoundation/AVAudioSession.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>
#import <CoreMedia/CMBlockBuffer.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioServices.h>
#import "CSSettings.h"
#import "CSDataStore.h"
#import "Formatting.h"
#import "CSSensePlatform.h"

static NSString* CONSUMER_NAME = @"nl.sense.sensors.noise_sensor";

//Declare private methods using empty category
@interface CSNoiseSensor()
- (void) startRecording;
- (void) scheduleRecording;
@end

@implementation CSNoiseSensor {
    AVAudioRecorder* audioRecorder;
    NSTimeInterval sampleInterval;
    NSTimeInterval sampleDuration;
	   
    dispatch_queue_t recordQueue;
    
    double lowPassResults;
    NSURL* recording;
    int numberOfPackets;
    BOOL interruptedOnRecording;
    BOOL sampleOnlyWhenScreenLocked;
    BOOL screenIsOn;
    
    NSArray* requirements;
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
        
        //subscribe to sensor data
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNewData:) name:kCSNewSensorDataNotification object:nil];
        
        //register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeAmbience] object:nil];
        
		
		//register for audio session route changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(configureAudioSession)
													 name:AVAudioSessionRouteChangeNotification object:nil];

		
        sampleInterval = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval] doubleValue];
        sampleDuration = 3; // seconds
        
        recordQueue = dispatch_queue_create("com.sense.platform.noiseRecord", NULL);

        numberOfPackets = 0;
        screenIsOn = YES;
        sampleOnlyWhenScreenLocked = YES;
        
        self->requirements = @[@{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_SCREEN_STATE}];
	}
	return self;
}

/** Configure the audio session of the app
 *
 */
- (void) configureAudioSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *activationError = nil;
    NSError *categoryError = nil;
	NSError *modeError = nil;
	
    // audio session category
    NSString *appAudioSessionCategory = AVAudioSessionCategoryPlayAndRecord;
    
    // Sets audio session category and mode=default
    if (![session setCategory:appAudioSessionCategory withOptions:AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionAllowBluetooth error:&categoryError]) {
        NSLog(@"Audio session can't set category. Error: %@", categoryError);
    }
	
	if(![session setMode:AVAudioSessionModeMeasurement error:&modeError]) {
		NSLog(@"Audio session can't set mode. Error: %@", modeError);
	}
	
    // activate session
    if (![session setActive:YES error:&activationError]) {
        NSLog(@"Audio session can't be activated. Error: %@", activationError);
    }
}

/** Initalize and configure the audio recorder
 *
 */
- (void) configureAudioRecording
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
        [audioRecorder prepareToRecord];
    }
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
    
    BOOL started = NO;
    
    // sample continuously, independant of the state of the screen
    if (sampleOnlyWhenScreenLocked == NO) {
        NSLog(@"start recording audio");
        started = [audioRecorder recordForDuration:sampleDuration];
    }
    // sample only when the screen is locked
    else {
        if (screenIsOn == NO) {
            NSLog(@"start recording audio");
            started = [audioRecorder recordForDuration:sampleDuration];
        }
    }
    
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
    
	NSLog(@"%@ noise sensor (id=%@)", enable ? @"Enabling" : @"Disabling", self.sensorId);
	isEnabled = enable;
	if (enable) {
        if (sampleOnlyWhenScreenLocked)
            [[CSSensorRequirements sharedRequirements] setRequirements:self->requirements byConsumer:CONSUMER_NAME];

		if (NO==audioRecorder.recording) {
            // configure the audio session
            [self configureAudioSession];
            // configure the audio recorder
            [self configureAudioRecording];

            [self startRecording];
		}
	} else {
		[audioRecorder stop];
		audioRecorder.delegate = nil;
        NSError* error;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
        [[CSSensorRequirements sharedRequirements] clearRequirementsForConsumer:CONSUMER_NAME];
	}
    isEnabled = enable;
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)didSucceed {
    if (didSucceed ==TRUE) {
        // calculate the audio recording volume in dBs
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
    //else {
    //    NSLog(@"Number of pakcets: %llu\n", packetsCount);
    //}
    numberOfPackets = (int) packetsCount;
    
    rawSampleData = (short int*) malloc(numberOfPackets * sizeof(short int));

    for (int i=0; i<(numberOfPackets); i++) {
        rawSampleData[i] = 0;
        result = AudioFileReadPacketData(recordingFile, YES, &numberOfBytesToRead, NULL, i, &numberOfPacketsToRead, &sampleData);
        if (result != noErr) {
            NSLog(@"Couldn't read audio data from recording file. Error: %d", (int) result);
        }

        rawSampleData[i] = sampleData;
        sumOfRawSampleData = sumOfRawSampleData + (rawSampleData[i] * rawSampleData[i]);
    }
    
    avgOfRawSampleData = sumOfRawSampleData / numberOfPackets;
    rootAvgOfRawSampleData = sqrt(avgOfRawSampleData);
    volumeOfAudioSignal = 10 * (log10(avgOfRawSampleData));
    
    //take timestamp
    double timestamp = [[NSDate date] timeIntervalSince1970];
    
    double level = volumeOfAudioSignal;
	
    NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
                                        CSroundedNumber(level, 1), @"value",
                                        CSroundedNumber(timestamp, 3), @"date",
                                        nil];
	if (numberOfPackets > 0) {
        [dataStore commitFormattedData:valueTimestampPair forSensorId:[self sensorId]];
    }
    
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
            // enable the screen sensor if it is disabled when you want to sample only when the screen is locked
            if (sampleOnlyWhenScreenLocked == YES) {
                [[CSSensorRequirements sharedRequirements] setRequirements:self->requirements byConsumer:CONSUMER_NAME];
            } else {
                [[CSSensorRequirements sharedRequirements] clearRequirementsForConsumer:CONSUMER_NAME];
            }
        }
	}
	@catch (NSException * e) {
		NSLog(@"%@: Exception thrown while changing setting: %@", self.name, e);
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
    if ([sensor isEqualToString:kCSSENSOR_SCREEN_STATE]) {
        // if receive dispaly event and the sampleonly flag is no do nothing otherwise call schedule but
        // if you record stop
        NSString* json = [notification.userInfo valueForKey:@"value"];
        NSString *screenState = [json valueForKey:@"screen"];
        
        // keep track of the state of the screen
        if ([screenState isEqualToString:@"off"])
            screenIsOn = NO;
        else {
            screenIsOn = YES;
            if ([audioRecorder isRecording] == YES) {
                [audioRecorder stop];
            }
        }
    }
}

@end
