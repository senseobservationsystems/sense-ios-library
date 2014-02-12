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

#import "CSSensePlatform.h"
#import "CSSensorStore.h"
#import "CSSettings.h"
#import "CSApplicationStateChange.h"

#import <UIKit/UIKit.h>
#import "UIDevice+IdentifierAddition.h"
#import "UIDevice+Hardware.h"

#import "CSLocationSensor.h"
#import "CSBatterySensor.h"
#import "CSCompassSensor.h"
#import "CSAccelerometerSensor.h"
#import "CSOrientationSensor.h"
#import "CSJumpSensor.h"
#import "CSUserProximity.h"
#import "CSOrientationStateSensor.h"
#import "CSNoiseSensor.h"
#import "CSCallSensor.h"
#import "CSConnectionSensor.h"
#import "CSPreferencesSensor.h"
#import "BloodPressureSensor.h"
#import "CSScreenSensor.h"
#import <sqlite3.h>
#import "CSSender.h"

#import "CSSpatialProvider.h"

//actual limit is 1mb, make it a little smaller to compensate for overhead and to be sure
#define MAX_BYTES_TO_UPLOAD_AT_ONCE (800*1024)
#define MAX_UPLOAD_INTERVAL 3600

@interface CSSensorStore (private)
- (void) applyGeneralSettings;
- (BOOL) uploadData;
- (void) instantiateSensors;
- (NSUInteger) nrPointsToSend:(NSArray*) data;
@end


@implementation CSSensorStore {
    CSSender* sender;
	
	NSMutableDictionary* sensorData;
	BOOL serviceEnabled;
	NSTimeInterval syncRate;
    NSTimeInterval waitTime;
	NSDate* lastUpload;
	NSTimeInterval pollRate;
	NSDate* lastPoll;
    dispatch_queue_t uploadQueueGCD;
    dispatch_queue_t uploadTimerQueueGCD;
    dispatch_source_t uploadTimerGCD;
    NSObject* uploadTimerLock;
	
	//Sensor classes, this variable is used to instantiate sensors
	NSArray* allSensorClasses;
	NSArray* allAvailableSensorClasses;
	NSMutableArray* sensors;
    NSMutableDictionary* sensorIdMap;
    NSObject* sensorIdMapLock;
	
	CSSpatialProvider* spatialProvider;
}
@synthesize allAvailableSensorClasses;
@synthesize sensors;
@synthesize sender;

//Singleton instance
static CSSensorStore* sharedSensorStoreInstance = nil;

+ (CSSensorStore*) sharedSensorStore {
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
		sender = [[CSSender alloc] init];
		//setup attributes
		sensorData = [[NSMutableDictionary alloc] init];
        uploadQueueGCD = dispatch_queue_create("com.sense.sense_platform.uploadQueue", NULL);
        uploadTimerQueueGCD = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        uploadTimerLock = [[NSObject alloc] init];

		lastUpload = [NSDate date];
		lastPoll = [NSDate date];
        sensorIdMapLock = [[NSObject alloc] init];
		
		//all sensor classes
		allSensorClasses = [NSArray arrayWithObjects:
							[CSLocationSensor class],
							[CSBatterySensor class],
							[CSCallSensor class],
 							[CSConnectionSensor class],
   							[CSNoiseSensor class],
							[CSOrientationSensor class],
							//[CSCompassSensor class],
							//[UserProximity class],
							//[OrientationStateSensor class],
 							[CSAccelerometerSensor class],
							[CSAccelerationSensor class],
							[CSRotationSensor class],
                            [CSScreenSensor class],
                            //[CSJumpSensor class],
							//[PreferencesSensor class],
							//[BloodPressureSensor class],
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged) name:CSsettingLoginChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeGeneral] object:nil];
	}
	return self;
}


- (void) makeRemoteDeviceSensors {
    NSMutableDictionary* mySensorIdMap = [NSMutableDictionary new];
    
    BOOL stop = NO;
	//get list of sensors from the server
    NSDictionary* response;
    @try {
        response = [sender listSensors];
    } @catch (NSException* e) {
        stop = YES;
    }
    
  	NSArray* remoteSensors = [response valueForKey:@"sensors"];
    //NSLog(@"Response: '%@', sensor list: '%@'", response, remoteSensors);
    if (stop || remoteSensors == nil) {
        //for some reason the request failed, so stop. Trying to create the sensors might result in duplicate sensors.
        NSLog(@"Couldn't get a list of sensors. Don't make ");
        return;
    }

    //push all ids in the sensorId map
    for (id remoteSensor in remoteSensors) {
        //determine whether the sensor matches
        if ([remoteSensor isKindOfClass:[NSDictionary class]]) {
            NSString* remoteId = [remoteSensor valueForKey:@"id"];
            NSString* name = [remoteSensor valueForKey:@"name"];
            NSString* deviceType = [remoteSensor valueForKey:@"device_type"];
            NSDictionary* device = [remoteSensor valueForKey:@"device"];
            NSString* sensorId = [CSSensor sensorIdFromName:name andDeviceType:deviceType andDevice:device];
            //update sensor id map
            [mySensorIdMap setValue:remoteId forKey:sensorId];
        }
    }

    bool allSucces = YES;
	//create sensors that aren't assigned an id yet
	for (CSSensor* sensor in sensors) {
		if ([mySensorIdMap objectForKey:sensor.sensorId] == NULL) {
			NSLog(@"Creating %@ sensor...", sensor.sensorId);
			NSDictionary* description = [sender createSensorWithDescription:[sensor sensorDescription]];
            id sensorIdString = [description valueForKey:@"id"];
   			if (description != nil && sensorIdString != nil) {
				//link sensor to device
                if (sensor.device != nil) {
                    [sender connectSensor:sensorIdString ToDevice:sensor.device];
                }
                //store sensor id in the map
  				[mySensorIdMap setValue:sensorIdString forKey:sensor.sensorId];
				NSLog(@"Created %@ sensor with id %@", sensor.sensorId, sensorIdString);
			} else {
                allSucces = NO;
            }
		}
	}
    
    @synchronized(sensorIdMapLock) {
        sensorIdMap = mySensorIdMap;
    }
}

- (void) instantiateSensors {
    @synchronized(sensors) {
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
	for (CSSensor* sensor in sensors) {
		sensor.dataStore = self;
	}
	
	//initialise spatial provider
	CSCompassSensor* compass=nil; CSOrientationSensor* orientation=nil; CSAccelerometerSensor* accelerometer=nil; CSAccelerationSensor* acceleration = nil; CSRotationSensor* rotation = nil; CSJumpSensor* jumpSensor = nil;
	for (CSSensor* sensor in sensors) {
		if ([sensor isKindOfClass:[CSCompassSensor class]])
			compass = (CSCompassSensor*)sensor;
		else if ([sensor isKindOfClass:[CSOrientationSensor class]])
			orientation = (CSOrientationSensor*)sensor;
		else if ([sensor isKindOfClass:[CSAccelerometerSensor class]])
			accelerometer = (CSAccelerometerSensor*)sensor;
		else if ([sensor isKindOfClass:[CSAccelerationSensor class]])
			acceleration = (CSAccelerationSensor*)sensor;
		else if ([sensor isKindOfClass:[CSRotationSensor class]])
			rotation = (CSRotationSensor*)sensor;
        else if ([sensor isKindOfClass:[CSJumpSensor class]])
			jumpSensor = (CSJumpSensor*)sensor;
	}
	
	spatialProvider = [[CSSpatialProvider alloc] initWithCompass:compass orientation:orientation accelerometer:accelerometer acceleration:acceleration rotation:rotation jumpSensor:jumpSensor];
        
    }
}

- (void) addSensor:(CSSensor*) sensor {
    @synchronized(sensors) {
        sensor.dataStore = self;
        for(CSSensor* s in sensors) {
            if ([s.sensorId isEqualToString:sensor.sensorId]) {
                //list already contains sensor, don't add
                return;
            }
        }
        
        [sensors addObject:sensor];
    }
}
- (void) commitFormattedData:(NSDictionary*) data forSensorId:(NSString *)sensorId {
    NSString* sensorName = [[[sensorId stringByReplacingOccurrencesOfString:@"//" withString:@"/"] componentsSeparatedByString:@"/"] objectAtIndex:0];
    //post notification for the data
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSNewSensorDataNotification object:sensorName userInfo:data];

    if ([[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense] isEqualToString:kCSSettingNO]) return;
    
    //FIXME: TODO: ugly hack to not send burst sensors
    //if ([sensorId rangeOfString:@"burst-mode"].location != NSNotFound) return;

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
    CSLocationSensor* locationSensor;
    @synchronized(sensors) {
    for (CSSensor* s in sensors) {
        if ([s.name isEqualToString:kCSSENSOR_LOCATION]) {
            locationSensor = (CSLocationSensor*)s;
            break;
        }
    }

	if (NO == enable) {
		/* Previously sensors were deallocated (by removing their references), however that has some problems
         * - the noise sensor uses a callback that cannot be unregistered, so deallocating the object while the callback may still use it is unwise
         * - due to blocks being used as callbacks and other sources of references, it is actually quite hard to deallocate some objects. This might lead to multiple instances of the same sensor, which is not a good thing.
         */
        //disable sensors
		for (CSSensor* sensor in sensors) {
			[[CSSettings sharedSettings] setSensor:sensor.name enabled:NO persistent:NO];
		}

        [locationSensor setBackgroundRunningEnable:NO];
		//flush data
		[self forceDataFlush];
        
        //set timer
        [self stopUploading];
	} else {
        [locationSensor setBackgroundRunningEnable:YES];
        //send notifications to notify sensors whether they should activate themselves
        for (CSSensor* sensor in sensors) {
			[[CSSettings sharedSettings] sendNotificationForSensor:sensor.name];
        }
        //enable uploading
        [self setSyncRate:syncRate];
	}
    waitTime = 0;
    }
}

- (void) loginChanged {
	//flush current data before making any changes
	[self forceDataFlush];
	
	//get new settings
    NSString* username = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
  	NSString* passwordHash = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword];
    NSLog(@"Sensorstore loginChanged:%@", username);
	//change login
    [sender setUser:username andPasswordHash:passwordHash];
    
    @synchronized(sensorIdMapLock) {
        sensorIdMap = nil;
    }
    waitTime = 0;
}

- (void) uploadAndClearData {
    dispatch_sync(uploadQueueGCD, ^{
        @autoreleasepool {
            @try {
               	[self uploadData];
            }
            @catch (NSException *exception) {
                [self uploadData];
            }
        }
    });

	@synchronized(self){
		[sensorData removeAllObjects];
	}
}

- (void) scheduleUploadIn:(NSTimeInterval) interval {
    /* Use a timer instead of dispatch_after so we can add some leeway and allow the scheduler to optimise. */
    @synchronized(uploadTimerLock) {
        if (uploadTimerGCD) {
            dispatch_source_cancel(uploadTimerGCD);
        }
        uint64_t leeway = MAX(interval * 0.1, 1ull) * NSEC_PER_SEC;
        uploadTimerGCD = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, uploadTimerQueueGCD);
        dispatch_source_set_event_handler(uploadTimerGCD, ^{
            dispatch_async(uploadQueueGCD, ^{
                @autoreleasepool {
                [self uploadOperation];
                }
            });
        });
        dispatch_source_set_timer(uploadTimerGCD, dispatch_walltime(NULL, interval * NSEC_PER_SEC), DISPATCH_TIME_FOREVER, leeway);
        dispatch_resume(uploadTimerGCD);
    }
}

- (void) stopUploading {
    @synchronized(uploadTimerLock) {
        if (uploadTimerGCD) {
            dispatch_source_cancel(uploadTimerGCD);
            uploadTimerGCD = NULL;
        }
    }
}

- (void) uploadOperation {
    BOOL allSucceed = NO;
    @try {
        allSucceed = [self uploadData];
    } @catch (NSException* exception) {
        NSLog(@"Exception during upload: %@", exception);
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
        [self scheduleUploadIn:interval];
        NSLog(@"Uploading again in %f seconds.", interval);
        
        //send notification about upload
        CSApplicationStateChangeMsg* msg = [[CSApplicationStateChangeMsg alloc] init];
        msg.applicationStateChange = allSucceed ? kCSUPLOAD_OK :kCSUPLOAD_FAILED;
        [[NSNotificationCenter defaultCenter] postNotification: [NSNotification notificationWithName:CSapplicationStateChangeNotification object:msg]];
    }
}



- (BOOL) uploadData {
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
            //skip this sensor if we don't have a remote id for this sensor.
            allSucceed = NO;
            continue;
        }
        //split the data, as the server limits the size per request
        //TODO: refactor this ugly but critical code, a proper transparent implementation should be done with respect to error handling
        while (data.count > 0) {
            //determine number of points to sent use heuristic to estimate size
            NSUInteger points = [self nrPointsToSend:data];

            NSRange range = NSMakeRange(0, points);
            NSArray* dataPart = [data subarrayWithRange:range];
            BOOL succeed = NO;
            @try {
                succeed = [sender uploadData:dataPart forSensorId: [sensorIdMap valueForKey:sensorId]];
            } @catch (NSException* e) {
                NSLog(@"SenseStore: Exception while uploading data: %@", e);
            }
            
            if (succeed == YES ) {
                //remove sent data
                [data removeObjectsInRange:range];
            } else {
                allSucceed = NO;
                NSLog(@"Upload failed");
                //don't check the reason for failure, just erase this sensor id
                @synchronized(sensorIdMapLock) {
                    [sensorIdMap removeObjectForKey:sensorId];
                }
                //get out of this loop and continue with the next sensor.
                break;
            }
        }
	}
    
    //resubmit unsent data (if any)  into sensorData
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
    return allSucceed;
}

- (NSArray*) getDataForSensor:(NSString*) name onlyFromDevice:(bool) onlyFromDevice nrLastPoints:(NSInteger) nrLastPoints {
    @try {
        NSString* sensorId = [self resolveSensorIdForSensorName:name onlyThisDevice:onlyFromDevice];
        
        if (sensorId) {
            return [sender getDataFromSensor:sensorId nrPoints:nrLastPoints];
        } else
            return nil;
    }
    @catch (NSException *exception) {
        return NULL;
    }
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
		//get new settings
        NSString* username = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
        NSString* passwordHash = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword];
        
		//apply properties one by one
		[sender setUser:username andPasswordHash:passwordHash];
        //TODO:FIX
		NSString* setting = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval];
        if ([setting isEqualToString:kCSGeneralSettingUploadIntervalAdaptive])
            [self setSyncRate:10];
        else if ([setting isEqualToString:kCSGeneralSettingUploadIntervalNightly])
            [self setSyncRate:3600];
        else if ([setting isEqualToString:kCSGeneralSettingUploadIntervalWifi])
            [self setSyncRate:3600];
        else if ([setting doubleValue]) {   
            [self setSyncRate:MAX(1,[setting doubleValue])];
        } else {
            [self setSyncRate:1800]; //Hmm, unknown, let's choose some value
        }
        
		[self setEnabled:[[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingSenseEnabled] boolValue]];
	}
	@catch (NSException * e) {
		NSLog(@"SenseStore: Exception thrown while updating general settings: %@", e);
	}	
}


- (void) forceDataFlushAndBlock {
    dispatch_sync(uploadQueueGCD, ^{
        @autoreleasepool {
            @try {
                [self uploadData];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception during forced data flush and block: %@", exception);
            }

        }
    });
}

- (void) forceDataFlush {
    dispatch_async(uploadQueueGCD, ^{
        @autoreleasepool {
            @try {
                [self uploadData];
            }
            @catch (NSException *exception) {
                 NSLog(@"Exception during forced data flush and block: %@", exception);
            }
        }
    });
}

- (void) generalSettingChanged: (NSNotification*) notification {
	if ([notification.object isKindOfClass:[CSSetting class]]) {
		CSSetting* setting = notification.object;
		if ([setting.name isEqualToString:kCSGeneralSettingUploadInterval]) {
            
            if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalAdaptive])
                [self setSyncRate:10];
            else if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalNightly])
                [self setSyncRate:3600];
            else if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalWifi])
                [self setSyncRate:3600];
            else if ([setting.value doubleValue]) {   
                    [self setSyncRate:MAX(1,[setting.value doubleValue])];
            } else {
                    [self setSyncRate:1800]; //Hmm, unknown, let's choose some value
            }
		} else if ([setting.name isEqualToString:kCSGeneralSettingSenseEnabled]) {
			[self setEnabled:[setting.value boolValue]];
		}
	}
}

- (void) setSyncRate: (int) newRate {
	syncRate = newRate;
    if (serviceEnabled) {
        [self scheduleUploadIn:syncRate];
    }
    NSLog(@"set upload interval: %d", newRate);
}

- (NSUInteger) nrPointsToSend:(NSArray*) data {
    //Heuristic to estimate the nr of points to send.
    NSUInteger points=0;
    int size = 0;
    NSError* error = nil;
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[data objectAtIndex:points] options:0 error:&error];
	NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    int sizeOfNextPoint = [json length];
    do {
        points++;
        size += sizeOfNextPoint;
        if (points >= data.count)
            break; //there is no next point...
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:[data objectAtIndex:points] options:0 error:&error];
        NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        sizeOfNextPoint = [json length];

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
        NSString* name = [CSSensor sensorNameFromSensorId:extendedID];
        if ([name isEqualToString:sensorName]) {
            //found sensor name
            sensorId = [sensorIdMap valueForKey:extendedID];
            break;
        }
    }
    
    //in case it isn't in the local mapping, resolve the sensor id remotely
    if (sensorId == nil) {
        //get list of sensors from the server
        NSDictionary* response;
        @try {
            if (onlyThisDevice)
                response = [sender listSensorsForDevice:[CSSensorStore device]];
            else 
                response = [sender listSensors];
        } @catch (NSException* e) {
            //for some reason the request failed, so stop. Trying to create the sensors might result in duplicate sensors.
            NSLog(@"Couldn't get a list of sensors for the device: %@ ", e.description);
            return nil;
        }
        NSArray* remoteSensors = [response valueForKey:@"sensors"];
        
        if (remoteSensors == nil)
            return nil;
        
        //match against all remote sensors
        for (id remoteSensor in remoteSensors) {
            //determine whether the sensor matches
            if ([remoteSensor isKindOfClass:[NSDictionary class]]) {
                NSString* dName = [remoteSensor valueForKey:@"name"];
                NSString* deviceType = [remoteSensor valueForKey:@"device_type"];
                NSDictionary* device = [remoteSensor valueForKey:@"device"];
                if (dName == nil || ([sensorName caseInsensitiveCompare:dName] != NSOrderedSame))
                    continue;
                
                sensorId = [remoteSensor valueForKey:@"id"];
                //update sensor id map
                @synchronized(sensorIdMapLock) {
                    [sensorIdMap setValue:sensorId forKey:[CSSensor sensorIdFromName:sensorName andDeviceType:deviceType andDevice:device]];
                }
                break;
            }
        }
    }

    return sensorId;
}


+ (NSDictionary*) device {
    NSString* type = [[UIDevice currentDevice] platformString];

 	NSUUID* uuid = [[UIDevice currentDevice] identifierForVendor];
	//NSString* uuid = [[UIDevice currentDevice] uniqueGlobalDeviceIdentifier];
	NSDictionary* device = [NSDictionary dictionaryWithObjectsAndKeys:
							[uuid UUIDString], @"uuid",
							type, @"type",
							nil];
	return device;
}
@end

