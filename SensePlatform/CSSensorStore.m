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

#import "CSLocationSensor.h"
#import "CSVisitsSensor.h"
#import "CSBatterySensor.h"
#import "CSCompassSensor.h"
#import "CSAccelerometerSensor.h"
#import "CSActivityProcessorSensor.h"
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
#import "CSSender.h"
#import "CSStorage.h"
#import "CSUploader.h"
#import "CSStepCounterProcessorSensor.h"
#import "CSTimeZoneSensor.h"

#import "CSSpatialProvider.h"
#import "CSLocationProvider.h"

#import "DSECallback.h"

@import DSESwift;

//actual limit is 1mb, make it a little smaller to compensate for overhead and to be sure
#define MAX_BYTES_TO_UPLOAD_AT_ONCE (800*1024)
#define MAX_UPLOAD_INTERVAL 3600
#define LOCAL_STORAGE_TIME 3600*24*31 //thirty-one days in seconds
#define TIME_INTERVAL_TO_CHECK_DATA_REMOVAL 3600*12 //12 hours in seconds

@interface CSSensorStore (private)
- (void) applyGeneralSettings;
- (BOOL) uploadData;
- (void) instantiateSensors;
- (NSUInteger) nrPointsToSend:(NSArray*) data;

@end


@implementation CSSensorStore {
    CSSender* sender;
    CSStorage* storage;
    CSUploader* uploader;
	
	NSMutableDictionary* sensorData;
	BOOL serviceEnabled;
	NSTimeInterval syncRate;
    NSTimeInterval waitTime;
	NSDate* lastUpload;
    NSDate* lastDeletionDate;
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
	CSLocationProvider* locationProvider;
}
@synthesize allAvailableSensorClasses;
@synthesize sensors;
@synthesize sender;

//Singleton instance
static CSSensorStore* sharedSensorStoreInstance = nil;

+ (CSSensorStore*) sharedSensorStore {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		sharedSensorStoreInstance = [[[super class] alloc] init];
    });
	return sharedSensorStoreInstance;	
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
        lastDeletionDate = [NSDate date];
        sensorIdMapLock = [[NSObject alloc] init];
        NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
        NSString* dbPath =[rootPath stringByAppendingPathComponent:@"data.db"];
        storage = [[CSStorage alloc] initWithPath:dbPath];
        uploader = [[CSUploader alloc] initWithStorage:storage andSender:sender];
		
		//all sensor classes
		allSensorClasses = [NSArray arrayWithObjects:
							[CSLocationSensor class],
							[CSVisitsSensor class],
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
							//[CSActivityProcessorSensor class],
                            [CSTimeZoneSensor class],
                            //[CSStepCounterProcessorSensor class],
							nil];
		
		NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"isAvailable == YES"];
		allAvailableSensorClasses = [allSensorClasses filteredArrayUsingPredicate:availablePredicate];
		sensors = [[NSMutableArray alloc] init];
        
        //instantiate sample strategy
        //sampleStrategy = [[SampleStrategy alloc] init];

        
		//set settings and initialise sensors
        if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
            [self instantiateSensors];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^() {
                [self instantiateSensors];
            });
        }
            
		[self applyGeneralSettings];
        
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged) name:CSsettingLoginChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeGeneral] object:nil];
	}
	return self;
}

- (void) instantiateSensors {
    @synchronized(sensors) {
		//release current sensors
		spatialProvider=nil;
		[sensors removeAllObjects];
		
		//instantiate sensors
		for (Class aClass in allAvailableSensorClasses) {
			if ([aClass isAvailable]) {
				CSSensor* newSensor = (CSSensor*)[[aClass alloc] init];
				[sensors addObject:newSensor];
				//save sensor description in storage
				if (newSensor.sensorDescription != nil) {
					NSString* type = [newSensor.device valueForKey:@"type"];
					NSString* uuid = [newSensor.device valueForKey:@"uuid"];
					NSData* jsonData = [NSJSONSerialization dataWithJSONObject:newSensor.sensorDescription options:0 error:nil];
					NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
					[self->storage storeSensorDescription:json forSensor:newSensor.name description:newSensor.deviceType deviceType:type device:uuid];
				}
			}
		}
		
		//set self as data store
		for (CSSensor* sensor in sensors) {
			sensor.dataStore = self;
		}
		
		//initialise spatial provider
		CSCompassSensor* compass=nil; CSOrientationSensor* orientation=nil; CSAccelerometerSensor* accelerometer=nil; CSAccelerationSensor* acceleration = nil; CSRotationSensor* rotation = nil; CSJumpSensor* jumpSensor = nil;
		CSLocationSensor* location = nil; CSVisitsSensor* visits = nil;
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
			else if ([sensor isKindOfClass:[CSLocationSensor class]])
				location = (CSLocationSensor*) sensor;
			else if ([sensor isKindOfClass:[CSVisitsSensor class]])
				visits = (CSVisitsSensor*) sensor;
		}
		
		spatialProvider = [[CSSpatialProvider alloc] initWithCompass:compass orientation:orientation accelerometer:accelerometer acceleration:acceleration rotation:rotation jumpSensor:jumpSensor];
		locationProvider = [[CSLocationProvider alloc] initWithLocationSensor:location andVisitsSensor:visits];
    }
}

- (void) initializeDSEWithSessionId: (NSString*) sessionId andUserId:(NSString*) userId andAppKey:(NSString*) appKey{
    NSError* error = nil;
    DataStorageEngine* dse = [DataStorageEngine getInstance];
    DSEConfig* dseConfig = [[DSEConfig alloc] init];
    dseConfig.sessionId = sessionId;
    dseConfig.userId = userId;
    dseConfig.appKey = appKey;
    [dse setup:dseConfig error:&error];
    if (error){
        NSLog(@"Error: %@",error);
        return;
    }
    
    //TODO: put proper callbacks
    void (^successHandler)() = ^(){NSLog(@"successcallback");};
    void (^failureHandler)(enum DSEError) = ^(enum DSEError error){NSLog(@"Error:%ld", (long)error);};
    
    DSECallback *callback = [[DSECallback alloc] initWithSuccessHandler: successHandler
                                                      andFailureHandler: failureHandler];
    [dse setSensorsDownloadedCallback:callback];
    
    error = nil;
    [dse startAndReturnError:&error];
    if (error){
        NSLog(@"Error: %@",error);
        return;
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
        if (sensor.sensorDescription != nil) {
            NSString* type = [sensor.device valueForKey:@"type"];
            NSString* uuid = [sensor.device valueForKey:@"uuid"];
            NSData* jsonData = [NSJSONSerialization dataWithJSONObject:sensor.sensorDescription options:0 error:nil];
            NSString* json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self->storage storeSensorDescription:json forSensor:sensor.name description:sensor.deviceType deviceType:type device:uuid];
        }
    }
}

- (void) addDataForSensorId:(NSString*) sensorId dateValue:(NSDictionary*) dateValue {
    NSData* valueData;
    @try {
        valueData  =  [NSJSONSerialization dataWithJSONObject:dateValue options:0 error:NULL];
    }
    @catch (NSException *exception) {
        return;
    }

    NSString* value = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
    double timestamp = [[dateValue objectForKey:@"date"] doubleValue];
    NSString* name = [CSSensor sensorNameFromSensorId:sensorId];
    NSString* description = [CSSensor sensorDescriptionFromSensorId:sensorId];
    //TODO: these values are not being used
    NSString* deviceType = [CSSensor sensorDeviceTypeFromSensorId:sensorId];
    NSString* deviceUUID = [CSSensor sensorDeviceUUIDFromSensorId:sensorId];
    NSString* dataType = @""; //Not being used

   [storage storeSensor:name description:description deviceType:deviceType device:deviceUUID dataType:dataType value:value timestamp:timestamp];
}
- (void) commitFormattedData:(NSDictionary*) data forSensorId:(NSString *)sensorId {
    NSString* sensorName = [[[sensorId stringByReplacingOccurrencesOfString:@"//" withString:@"/"] componentsSeparatedByString:@"/"] objectAtIndex:0];
	//post notification for the data
    [[NSNotificationCenter defaultCenter] postNotificationName:kCSNewSensorDataNotification object:sensorName userInfo:data];

    if ([[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense] isEqualToString:kCSSettingNO]) return;
    BOOL dontUploadBursts = [[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingDontUploadBursts] isEqualToString:kCSSettingYES];
    if (dontUploadBursts && [sensorId rangeOfString:@"burst-mode"].location != NSNotFound) return;

    [self addDataForSensorId:sensorId dateValue:data];
}

- (void) enabledChanged:(id) notification {
    BOOL enable = [[notification object] boolValue];
    [self setEnabled:enable];
}

-(void) setEnabled:(BOOL) enable {
	serviceEnabled = enable;
    @synchronized(sensors) {

	if (NO == enable) {
		/* Previously sensors were deallocated (by removing their references), however that has some problems
         * - the noise sensor uses a callback that cannot be unregistered, so deallocating the object while the callback may still use it is unwise
         * - due to blocks being used as callbacks and other sources of references, it is actually quite hard to deallocate some objects. This might lead to multiple instances of the same sensor, which is not a good thing.
         */
        //disable sensors
		for (CSSensor* sensor in sensors) {
			[[CSSettings sharedSettings] setSensor:sensor.name enabled:NO persistent:NO];
		}

		//flush data
		[self forceDataFlush];
        
        //set timer
        [self stopUploading];
	} else {
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
    BOOL succeed =  [uploader upload];
    if (succeed) {
        if([lastDeletionDate timeIntervalSinceNow] > TIME_INTERVAL_TO_CHECK_DATA_REMOVAL) { // if last deletion was more than limit ago remove old data again
            
            //Clean up storage by removing data that is older than LOCAL_STORAGE_TIME
            NSDate *cutOffTime = [NSDate dateWithTimeIntervalSince1970: ([[NSDate date] timeIntervalSince1970] - LOCAL_STORAGE_TIME)];
            
            NSLog(@"Deleting all data before %@", [NSDateFormatter localizedStringFromDate:cutOffTime dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle]);
            
            [self->storage removeDataBeforeTime: cutOffTime];
            lastDeletionDate = [NSDate date]; // reset to now
        }
    }
    return succeed;
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
- (NSArray*) getLocalDataForSensor:(NSString *)name from:(NSDate *)startDate to:(NSDate *)endDate andOrder:(NSString *) order withLimit: (int) nrOfPoints {
    return [self->storage getDataFromSensor:name from:startDate to:endDate andOrder:order withLimit: nrOfPoints];
}

- (NSArray*) getLocalDataForSensor:(NSString *)sensorName andDeviceType:(NSString *) deviceType from:(NSDate *)startDate to:(NSDate *)endDate {
	return [self->storage getDataFromSensor:sensorName andDeviceType:deviceType from:startDate to:endDate];
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
                //flush to disk before uploading. In case of a flush we want to make sure the data is saved, even if the app cannot upload.
                [storage flush];
                [self uploadData];
                [self->storage flush];
            }
            @catch (NSException *exception) {
                NSLog(@"Exception during forced data flush and block: %@", exception);
            }

        }
    });
}

- (void) forceDataFlush {
    //flush to disk before uploading. In case of a flush we want to make sure the data is saved, even if the app cannot upload.
    [storage flush];
    //schedule an upload
    dispatch_async(uploadQueueGCD, ^{
        @autoreleasepool {
            @try {
                [self uploadData];
                [self->storage flush];
            }
            @catch (NSException *exception) {
                 NSLog(@"Exception during forced data flush and block: %@", exception);
            }
        }
    });
}

- (void) removeLocalData {
    [storage removeDataBeforeTime:[NSDate date]];
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
		} else if ([setting.name isEqualToString:kCSGeneralSettingBackgroundRestarthack]) {
            [self setBackgroundHackEnabled:[setting.value isEqualToString:kCSSettingYES]];
        }
	}
}

- (void) setBackgroundHackEnabled:(BOOL) enable {
	//when only enabling the locationProvider and not the locationSensor the location updates are used for background monitoring but are not stored
	locationProvider.isEnabled = YES;
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
    
    size_t sizeOfNextPoint = [json length];
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
    /* TODO: remove this. There is some code in uploader that could be used */
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
        NSArray* remoteSensors;
        @try {
            if (onlyThisDevice)
                remoteSensors = [sender listSensorsForDevice:[CSSensorStore device]];
            else 
                remoteSensors = [sender listSensors];
        } @catch (NSException* e) {
            //for some reason the request failed, so stop. Trying to create the sensors might result in duplicate sensors.
            NSLog(@"Couldn't get a list of sensors for the device: %@ ", e.description);
            return nil;
        }
        
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

- (void) requestLocationPermission {
    [locationProvider requestPermission];
}

- (CLAuthorizationStatus) locationPermissionState {
    return [locationProvider permissionState];
}




@end

