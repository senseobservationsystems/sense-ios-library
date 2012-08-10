//
//  sensorStore.m
//  senseLocationApp
//
//  Created by Pim Nijdam on 2/15/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SensePlatform.h"
#import "SensorStore.h"
#import "Settings.h"
#import "ApplicationStateChange.h"

#import "LocationSensor.h"
#import "BatterySensor.h"
#import "CompassSensor.h"
#import "AccelerometerSensor.h"
#import "OrientationSensor.h"
#import "JumpSensor.h"
#import "UserProximity.h"
#import "OrientationStateSensor.h"
#import "NoiseSensor.h"
#import "CallSensor.h"
#import "ConnectionSensor.h"
#import "PreferencesSensor.h"
#import "BloodPressureSensor.h"
#import "MiscSensor.h"
#import <sqlite3.h>
#import <UIKit/UIKit.h>
#import "Sender.h"

#import "SpatialProvider.h"

NSString* const kMotionData = @"motionData";

//actual limit is 1mb, make it a little smaller to compensate for overhead and to be sure
#define MAX_BYTES_TO_UPLOAD_AT_ONCE (800*1024)
#define MAX_UPLOAD_INTERVAL 3600

@interface SensorStore (private)
- (void) applyGeneralSettings;
- (void) uploadData;
- (void) instantiateSensors;
- (void) scheduleUpload;
- (NSUInteger) nrPointsToSend:(NSArray*) data;
@end



@implementation SensorStore {
    Sender* sender;
	
	NSMutableDictionary* sensorData;
	BOOL serviceEnabled;
	NSTimeInterval syncRate;
    NSTimeInterval waitTime;
	NSDate* lastUpload;
	NSTimeInterval pollRate;
	NSDate* lastPoll;
	NSOperationQueue* operationQueue;
	
	NSTimer* uploadTimer;
	
	//Sensor classes, this variable is used to instantiate sensors
	NSArray* allSensorClasses;
	NSArray* allAvailableSensorClasses;
	NSMutableArray* sensors;
    NSMutableDictionary* sensorIdMap;
	
	SpatialProvider* spatialProvider;
}
@synthesize allAvailableSensorClasses;
@synthesize sensors;
@synthesize sender;

//Singleton instance
static SensorStore* sharedSensorStoreInstance = nil;

+ (SensorStore*) sharedSensorStore {
	if (sharedSensorStoreInstance == nil) {
		sharedSensorStoreInstance = [[super allocWithZone:NULL] init];
	}
	return sharedSensorStoreInstance;	
}

//override to ensure singleton
+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedSensorStore];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id) init {
	self = [super init];
	if (self) {
		sender = [[Sender alloc] init];
		//setup attributes
		sensorData = [[NSMutableDictionary alloc] init];
		operationQueue = [[NSOperationQueue alloc] init];
		lastUpload = [NSDate date];
		lastPoll = [NSDate date];
		
		//all sensor classes
		allSensorClasses = [NSArray arrayWithObjects:
							[LocationSensor class],
							[BatterySensor class],
							[CallSensor class],
 							[ConnectionSensor class],
   							[NoiseSensor class],
							[OrientationSensor class],
							//[CompassSensor class],
							//[UserProximity class],
							//[OrientationStateSensor class],
 							[AccelerometerSensor class],
							[AccelerationSensor class],
							[RotationSensor class],
                            [JumpSensor class],
							//[PreferencesSensor class],
							//[BloodPressureSensor class],
							//[MiscSensor class],
							nil];
		
		NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"isAvailable == YES"];
		allAvailableSensorClasses = [allSensorClasses filteredArrayUsingPredicate:availablePredicate];
		sensors = [[NSMutableArray alloc] init];
        
        //instantiate sample strategy
        //sampleStrategy = [[SampleStrategy alloc] init];

        
		//set settings and initialise sensors
        [self instantiateSensors];
		[self applyGeneralSettings];
        
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged) name:settingLoginChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[Settings settingChangedNotificationNameForType:kSettingTypeGeneral] object:nil];
	}
	return self;
} 

- (void) makeRemoteDeviceSensors {
    if (sensorIdMap == nil)
        sensorIdMap = [NSMutableDictionary new];
    else {
        //refreshing the mapping, remove 'old' mapping so we can recreate sensor that have been removed at the server.
        [sensorIdMap removeAllObjects];
    }
    
    
	//get list of sensors from the server
    NSDictionary* response;
    @try {
        response = [sender listSensorsForDevice:[SensorStore device]];
    } @catch (NSException* e) {
        //for some reason the request failed, so stop. Trying to create the sensors might result in duplicate sensors.
        NSLog(@"Couldn't get a list of sensors for the device. Don't make ");
        return;
    }
	NSArray* remoteSensors = [response valueForKey:@"sensors"];
	
	//forall local sensors
	for (Sensor* sensor in sensors) {
		//match against all remote sensors
		for (id remoteSensor in remoteSensors) {
			//determine whether the sensor matches
			if ([remoteSensor isKindOfClass:[NSDictionary class]] && [sensor matchesDescription:remoteSensor]) {
				id sensorId = [remoteSensor valueForKey:@"id"];
                //update sensor id map
				[sensorIdMap setValue:sensorId forKey:sensor.sensorId];
				break;
			}
		}
	}
	
	//create sensors that aren't assigned an id yet
	for (Sensor* sensor in sensors) {
		if ([sensorIdMap objectForKey:sensor.sensorId] == NULL) {
			NSDictionary* description = [sender createSensorWithDescription:[sensor sensorDescription]];
            id sensorIdString = [description valueForKey:@"id"];
   			if (description != nil && sensorIdString != nil) {
				//link sensor to this device
				[sender connectSensor:sensorIdString ToDevice:[SensorStore device]];

                //store sensor id in the map
  				[sensorIdMap setValue:sensorIdString forKey:sensor.sensorId];
				NSLog(@"Created %@ sensor with id %@", sensor.sensorId, sensorIdString);
			}
		}
	}
}

- (void) instantiateSensors {
	//release current sensors
	spatialProvider=nil;
	[sensors removeAllObjects];
    
	//instantiate sensors
	for (Class aClass in allAvailableSensorClasses) {
		if ([aClass isAvailable]) {
			id newSensor = [[aClass alloc] init];
			[sensors addObject:newSensor];
		}
	}
    
	//set self as data store
	for (Sensor* sensor in sensors) {
		sensor.dataStore = self;
	}
	
	//initialise spatial provider
	CompassSensor* compass=nil; OrientationSensor* orientation=nil; AccelerometerSensor* accelerometer=nil; AccelerationSensor* acceleration = nil; RotationSensor* rotation = nil; JumpSensor* jumpSensor = nil;
	for (Sensor* sensor in sensors) {
		if ([sensor isKindOfClass:[CompassSensor class]])
			compass = (CompassSensor*)sensor;
		else if ([sensor isKindOfClass:[OrientationSensor class]])
			orientation = (OrientationSensor*)sensor;
		else if ([sensor isKindOfClass:[AccelerometerSensor class]])
			accelerometer = (AccelerometerSensor*)sensor;
		else if ([sensor isKindOfClass:[AccelerationSensor class]])
			acceleration = (AccelerationSensor*)sensor;
		else if ([sensor isKindOfClass:[RotationSensor class]])
			rotation = (RotationSensor*)sensor;
        else if ([sensor isKindOfClass:[JumpSensor class]])
			jumpSensor = (JumpSensor*)sensor;
	}
	
	spatialProvider = [[SpatialProvider alloc] initWithCompass:compass orientation:orientation accelerometer:accelerometer acceleration:acceleration rotation:rotation jumpSensor:jumpSensor];
}

- (void) addSensor:(Sensor*) sensor {
    sensor.dataStore = self;
    for(Sensor* s in sensors) {
        if ([s matchesDescription:[sensor sensorDescription]]) {
            //list already contains sensor, don't add
            return;
        }
    }

    [sensors addObject:sensor];
}
- (void) commitFormattedData:(NSDictionary*) data forSensorId:(NSString *)sensorId {
    NSString* sensorName = [[[sensorId stringByReplacingOccurrencesOfString:@"//" withString:@"/"] componentsSeparatedByString:@"/"] objectAtIndex:0];
    //post notification for the data
    [[NSNotificationCenter defaultCenter] postNotificationName:kNewSensorDataNotification object:sensorName userInfo:data];
    if ([[[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingUploadToCommonSense] isEqualToString:kSettingNO]) return;

	//retrieve/create entry for this sensor
	@synchronized(self) {
		NSMutableArray* entry = [sensorData valueForKey:sensorId];
		if (entry == nil) {
			entry = [[NSMutableArray alloc] init];
			[sensorData setValue:entry forKey:sensorId];
		}
        
		//add data
		[entry addObject:data];
	}
}

- (void) enabledChanged:(id) notification {
    BOOL enable = [[notification object] boolValue];
    [self setEnabled:enable];
}

-(void) setEnabled:(BOOL) enable {
	serviceEnabled = enable;
    LocationSensor* locationSensor;
    for (Sensor* s in sensors) {
        if ([s.name isEqualToString:kSENSOR_LOCATION]) {
            locationSensor = (LocationSensor*)s;
            break;
        }
    }

	if (NO == enable) { 
		/* Previously sensors were deallocated (by removing their references), however that has some problems
         * - the noise sensor uses a callback that cannot be unregistered, so deallocating the object while the callback may still use it is unwise
         * - due to blocks being used as callbacks and other sources of references, it is actually quite hard to deallocate some objects. This might lead to multiple instances of the same sensor, which is not a good thing.
         */
        //disable sensors
		for (Sensor* sensor in sensors) {
			[[Settings sharedSettings] setSensor:[sensor sensorId] enabled:NO permanent:NO];
		}
        
        [locationSensor setBackgroundRunningEnable:NO];
		//flush data
		[self forceDataFlush];
        
        //delete upload timer
        if (uploadTimer.isValid )
            [uploadTimer invalidate];
	} else {
        [locationSensor setBackgroundRunningEnable:YES];
        //send notifications to notify sensors whether they should activate themselves
        for (Sensor* sensor in sensors) {
			[[Settings sharedSettings] sendNotificationForSensor:sensor.name];
        }
        //enable uploading
        [self setSyncRate:syncRate];
	}
    waitTime = 0;
}

- (void) loginChanged {
	//flush current data before making any changes
	[self forceDataFlush];
	
	//get new settings
    NSString* username = [[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingUsername];
  	NSString* password = [[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingPassword];
    NSLog(@"Sensorstore loginChanged:%@", username);
	//change login
    [sender setUser:username andPassword:password];
    
    sensorIdMap = nil;
    waitTime = 0;
}

- (void) scheduleUpload {
	@try {
		//make an upload operation
		NSInvocationOperation* uploadOp = [[NSInvocationOperation alloc]
                                           initWithTarget:self selector:@selector(uploadData) object:nil];
        
		[operationQueue addOperation:uploadOp];
	}
	@catch (NSException * e) {
		NSLog(@"Catched exception while scheduling upload. Exception: %@", e);
	}
}

- (void) uploadAndClearData {
	[self uploadData];
	@synchronized(self){
		[sensorData removeAllObjects];
	}
    
}

- (void) uploadData {
    BOOL allSucceed = YES;
	NSMutableDictionary* myData;
	//take over sensorData
	@synchronized(self){
		myData = sensorData;
		sensorData = [NSMutableDictionary new];
	}
    
    //refresh sensors, if one of the id's isn't in the map
	for (NSString* sensorId in myData) {    
        if (sensorIdMap == nil || [sensorIdMap objectForKey:sensorId] == NULL) {
            [self makeRemoteDeviceSensors];
            break;
        }
    }
    
    //for all sensors we have data for, send the data
	for (NSString* sensorId in myData) {
        NSMutableArray* data= [myData valueForKey:sensorId];
        if ([sensorIdMap valueForKey:sensorId] == NULL) {
            allSucceed = NO;
            continue;
        }
        NSLog(@"Uploading data for sensor %@. %u point(s).", sensorId, data.count);
        //split the data, as the server limits the size per request
        //TODO: refactor this ugly but critical code, a proper transparent implementation should be done with respect to error handling
        while (data.count > 0) {
            //determine number of points to sent use heuristic to estimate size
            NSUInteger points = [self nrPointsToSend:data];

            NSRange range = NSMakeRange(0, points);
            NSArray* dataPart = [data subarrayWithRange:range];
            BOOL succeed = NO;
            @try {
                NSLog(@"Uploading batch of %d points.",points);
                succeed = [sender uploadData:dataPart forSensorId: [sensorIdMap valueForKey:sensorId]];
            } @catch (NSException* e) {
                NSLog(@"SenseStore: Exception while uploading data: %@", e);
            }
            
            if (succeed == YES ) {
                //remove sent data
                [data removeObjectsInRange:range];
            } else {
                NSLog(@"Upload failed");
                //don't check the reason for failure, just erase this sensor id
                [sensorIdMap removeObjectForKey:sensorId];
                //get out of this loop and continue with the next sensor.
                break;
            }
        }
	}
    
    //re submit unsent data (if any)  into sensorData
    @synchronized(self) {
        for (NSString* sensorId in myData) {
            NSMutableArray* unsent = [myData valueForKey:sensorId];
            if (unsent.count > 0) {
                NSMutableArray* entry = [sensorData valueForKey:sensorId];
                if (entry == nil) {
                    [sensorData setValue:unsent forKey:sensorId];
                }
                else {
                    [entry addObjectsFromArray:unsent];
                }
            }
        }
    }
    
    //exponentially back off at failures to avoid spamming the server
    if (allSucceed)
        waitTime = 0; //no need to back off
    else {
        //back off with a factor 2, max to one hour or upload interval
        waitTime = MIN(MAX(MAX_UPLOAD_INTERVAL, syncRate), MAX(2 * syncRate, 2 * waitTime));
    }
    
    if (serviceEnabled == YES) {
        NSTimeInterval interval = MAX(waitTime, syncRate);
        if (uploadTimer.isValid)
            [uploadTimer invalidate];
        uploadTimer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(scheduleUpload)    userInfo:nil repeats:NO];
        NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:uploadTimer forMode:NSRunLoopCommonModes];
        NSLog(@"Uploading again in %f seconds.", interval);
        
        //send notification about upload
        ApplicationStateChangeMsg* msg = [[ApplicationStateChangeMsg alloc] init];
        msg.applicationStateChange = allSucceed ? kUPLOAD_OK :kUPLOAD_FAILED;
        [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:applicationStateChangeNotification object:msg]];
        
        [runLoop run];
    }
}

- (NSDictionary*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints {
    NSString* sensorId = [self resolveSensorIdForSensorName:name onlyThisDevice:onlyFromDevice];    

    if (sensorId) {
        return [sender getDataFromSensor:sensorId nrPoints:nrLastPoints];
    } else
        return nil;
}

- (void) giveFeedbackOnState:(NSString*) state from:(NSDate*)from to:(NSDate*) to label:(NSString*)label {
    NSString* sensorId = [self resolveSensorIdForSensorName:state onlyThisDevice:NO];

    if (sensorId) {
        //make sure data is flushed
        [self forceDataFlushAndBlock];
        [sender giveFeedbackToStateSensor:sensorId from:from to:to label:label];
    }
}


- (void) applyGeneralSettings {
	@try {
		NSLog(@"applying general settings");
		//get new settings
        NSString* username = [[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingUsername];
        NSString* password = [[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingPassword];
        
		//apply properties one by one
		[sender setUser:username andPassword:password];
        //TODO:FIX
		NSString* setting = [[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingUploadInterval];
        if ([setting isEqualToString:kGeneralSettingUploadIntervalAdaptive])
            [self setSyncRate:10];
        else if ([setting isEqualToString:kGeneralSettingUploadIntervalNightly])
            [self setSyncRate:3600];
        else if ([setting isEqualToString:kGeneralSettingUploadIntervalWifi])
            [self setSyncRate:3600];
        else if ([setting doubleValue]) {   
            [self setSyncRate:MAX(1,[setting doubleValue])];
        } else {
            [self setSyncRate:1800]; //Hmm, unknown, let's choose some value
        }
        
		[self setEnabled:[[[Settings sharedSettings] getSettingType:kSettingTypeGeneral setting:kGeneralSettingSenseEnabled] boolValue]];
	}
	@catch (NSException * e) {
		NSLog(@"SenseStore: Exception thrown while updating general settings: %@", e);
	}	
}


- (void) forceDataFlushAndBlock {
    [self forceDataFlush];
    [operationQueue waitUntilAllOperationsAreFinished];
}

- (void) forceDataFlush {
	@try {
		//make an upload operation
		NSInvocationOperation* uploadOp = [[NSInvocationOperation alloc]
										   initWithTarget:self selector:@selector(uploadAndClearData) object:nil];
		
		[operationQueue addOperation:uploadOp];
	}
	@catch (NSException * e) {
		NSLog(@"Catched exception while scheduling upload. Exception: %@", e);
	}
}

- (void) generalSettingChanged: (NSNotification*) notification {
	if ([notification.object isKindOfClass:[Setting class]]) {
		Setting* setting = notification.object;
		NSLog(@"general setting changed: %@,%@", setting.name, setting.value);
		if ([setting.name isEqualToString:kGeneralSettingUploadInterval]) {
            
            if ([setting.value isEqualToString:kGeneralSettingUploadIntervalAdaptive])
                [self setSyncRate:10];
            else if ([setting.value isEqualToString:kGeneralSettingUploadIntervalNightly])
                [self setSyncRate:3600];
            else if ([setting.value isEqualToString:kGeneralSettingUploadIntervalWifi])
                [self setSyncRate:3600];
            else if ([setting.value doubleValue]) {   
                    [self setSyncRate:MAX(1,[setting.value doubleValue])];
            } else {
                    [self setSyncRate:1800]; //Hmm, unknown, let's choose some value
            }
		} else if ([setting.name isEqualToString:kGeneralSettingSenseEnabled]) {
			[self setEnabled:[setting.value boolValue]];
		}
	}
}

- (void) setSyncRate: (int) newRate {
	syncRate = newRate;
    if (serviceEnabled) {
        if (uploadTimer.isValid )
            [uploadTimer invalidate];
        uploadTimer = [NSTimer scheduledTimerWithTimeInterval:syncRate target:self selector:@selector(scheduleUpload) userInfo:nil repeats:NO];
    }
    NSLog(@"set upload interval: %d", newRate);
}

- (NSUInteger) nrPointsToSend:(NSArray*) data {
    //Heuristic to estimate the nr of points to send.
    NSUInteger points=0;
    int size = 0;
    int sizeOfNextPoint = [[[data objectAtIndex:points] JSONRepresentation] length];
    do {
        points++;
        size += sizeOfNextPoint;
        if (points >= data.count)
            break; //there is no next point...
        sizeOfNextPoint = [[[data objectAtIndex:points] JSONRepresentation] length];
        //add some bytes for overhead
        sizeOfNextPoint += 10;
    } while (size + sizeOfNextPoint < MAX_BYTES_TO_UPLOAD_AT_ONCE);
    return points;
}

- (NSString*) resolveSensorIdForSensorName:(NSString*) sensorName onlyThisDevice:(BOOL)onlyThisDevice {
    //try to resolve the id from the local mapping
    NSString* sensorId;
    for (NSString* extendedID in sensorIdMap) {
        //extract sensor name
        NSString* name = [Sensor sensorNameFromSensorId:extendedID];
        if ([name isEqualToString:sensorName]) {
            //found sensor name
            sensorId = [sensorIdMap valueForKey:extendedID];
            break;
        }
    }
    
    //TODO: in case it isn't in the local mapping, resolve the sensor id remotely
    if (sensorId == nil) {
        //get list of sensors from the server
        NSDictionary* response;
        @try {
            if (onlyThisDevice)
                response = [sender listSensorsForDevice:[SensorStore device]];
            else 
                response = [sender listSensors];
        } @catch (NSException* e) {
            //for some reason the request failed, so stop. Trying to create the sensors might result in duplicate sensors.
            NSLog(@"Couldn't get a list of sensors for the device: %@ ", e.description);
            return nil;
        }
        NSArray* remoteSensors = [response valueForKey:@"sensors"];
        
        //match against all remote sensors
        for (id remoteSensor in remoteSensors) {
            //determine whether the sensor matches
            if ([remoteSensor isKindOfClass:[NSDictionary class]]) {
                NSString* dName = [remoteSensor valueForKey:@"name"];
                NSString* deviceType = [remoteSensor valueForKey:@"device_type"];
                if (dName == nil || ([sensorName caseInsensitiveCompare:dName] != NSOrderedSame))
                    continue;
                
                sensorId = [remoteSensor valueForKey:@"id"];
                //update sensor id map
                [sensorIdMap setValue:sensorId forKey:[Sensor sensorIdFromName:sensorName andDeviceType:deviceType]];
                break;
            }
        }
    }
    
    return sensorId;
}



+ (NSDictionary*) device {
	NSString* type = [[UIDevice currentDevice] model];
	NSString* uuid = [[UIDevice currentDevice] uniqueIdentifier];
	NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							uuid, @"uuid",
							type, @"type",
							nil];
	return device;
}
@end

