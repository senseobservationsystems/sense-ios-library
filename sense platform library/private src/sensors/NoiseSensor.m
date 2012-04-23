//
//  NoiseSensor.m
//  senseApp
//
//  Created by Pim Nijdam on 3/1/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import "NoiseSensor.h"
#import <CoreAudio/CoreAudioTypes.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAssetReader.h>
#import <AVFoundation/AVAssetReaderOutput.h>
#import <CoreMedia/CMBlockBuffer.h>
#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioServices.h>
#import "Settings.h"
#import "DataStore.h"

//Declare private methods using empty category
@interface NoiseSensor()
- (void) startRecording;
- (void) scheduleRecording;
- (void) incrementVolume;
@end

@implementation NoiseSensor
@synthesize sampleTimer;
@synthesize volumeTimer;

- (NSString*) name {return kSENSOR_NOISE;}
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
		UInt32 allowMixing = true;
		propertySetError = AudioSessionSetProperty (
													kAudioSessionProperty_OverrideCategoryMixWithOthers,
													sizeof (allowMixing),
													&allowMixing
													);
		
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
		NSError* error;
		audioRecorder = [[AVAudioRecorder alloc] initWithURL:recording settings:nil error:&error];
		if (nil == audioRecorder) {
			NSLog(@"Recorder could not be initialised. Error: %@", error);
		}
		audioRecorder.delegate = self;
		audioRecorder.meteringEnabled = YES;
		
        
        //register for setting changes
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(settingChanged:)
													 name:[Settings settingChangedNotificationNameForType:kSettingTypeAmbience] object:nil];
        sampleInterval = [[[Settings sharedSettings] getSettingType:kSettingTypeAmbience setting:kAmbienceSettingInterval] doubleValue];
        sampleDuration = 2;
		volumeSampleInterval = 0.2;
	}
	return self;
}

- (void)  scheduleRecording {
	self.sampleTimer = [NSTimer scheduledTimerWithTimeInterval:sampleInterval target:self selector:@selector(startRecording) userInfo:nil repeats:NO];
}

- (void) startRecording {
	NSError* error = nil;
	//try to activate the session
	[[AVAudioSession sharedInstance] setActive:YES error:&error];
	audioRecorder.delegate = self;
	BOOL started = [audioRecorder recordForDuration:sampleDuration];
	//NSLog(@"recorder %@", started? @"started":@"failed to start");
	if (NO == started) {
		//try again later
		[self scheduleRecording];
		return;
	}
	volumeSum = 0;
	nrVolumeSamples = 0;
	self.volumeTimer = [NSTimer scheduledTimerWithTimeInterval:volumeSampleInterval target:self selector:@selector(incrementVolume) userInfo:nil repeats:YES];
}

- (void) incrementVolume {
	[audioRecorder updateMeters];
	volumeSum +=  pow(10, [audioRecorder averagePowerForChannel:0] / 20);
	++nrVolumeSamples;
}


- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
	//only react to changes
	//if (enable == isEnabled) return;
	
	NSLog(@"Enabling noise sensor (id=%@): %@", self.sensorId, enable ? @"yes":@"no");
	isEnabled = enable;
	if (enable) {
		if (NO==audioRecorder.recording) {
			[self startRecording];
		}
	} else {
		audioRecorder.delegate = nil;
		[audioRecorder stop];
		//cancel a scheduled recording
		[volumeTimer invalidate];
		self.volumeTimer = nil;
		[sampleTimer invalidate];
		self.sampleTimer = nil;
	}
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)didSucceed {
	NSLog(@"recorder stopped");
	[volumeTimer invalidate];
	self.volumeTimer = nil;
	if (didSucceed && nrVolumeSamples > 0)	{
		//take timestamp
		double timestamp = [[NSDate date] timeIntervalSince1970];

        double level = 20 * log10(volumeSum / nrVolumeSamples);
 
		//TODO: save file...
		[recorder deleteRecording];
	
		NSDictionary* valueTimestampPair = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSString stringWithFormat:@"%.1f", level], @"value",
											[NSString stringWithFormat:@"%.0f",timestamp], @"date",
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
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags {
	NSLog(@"recorder interruption ended");
	[recorder stop];
	[recorder deleteRecording];
	if (isEnabled) {
		//start a new recording
		[self startRecording];
	}
}


- (void) settingChanged: (NSNotification*) notification {
	@try {
		Setting* setting = notification.object;
		NSLog(@"noise: setting %@ changed to %@.", setting.name, setting.value);
		if ([setting.name isEqualToString:kAmbienceSettingInterval]) {
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
