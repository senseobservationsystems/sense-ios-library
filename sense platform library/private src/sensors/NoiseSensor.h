//
//  NoiseSensor.h
//  senseApp
//
//  Created by Pim Nijdam on 3/1/11.
//  Copyright 2011 Almende. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioRecorder.h>
#import "Sensor.h"


@interface NoiseSensor : Sensor <AVAudioRecorderDelegate> {
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
