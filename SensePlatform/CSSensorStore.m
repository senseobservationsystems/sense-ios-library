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
#import "CSStepCounterProcessorSensor.h"
#import "CSTimeZoneSensor.h"

#import "CSSpatialProvider.h"
#import "CSLocationProvider.h"

#import "DSECallback.h"
#import "CSSensorConstants.h"

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
		
		//all sensor classes
        allSensorClasses = [self getAllSensorClassesArray];
		
		NSPredicate* availablePredicate = [NSPredicate predicateWithFormat:@"isAvailable == YES"];
		allAvailableSensorClasses = [allSensorClasses filteredArrayUsingPredicate:availablePredicate];
		sensors = [[NSMutableArray alloc] init];
        
        //instantiate sample strategy
        //sampleStrategy = [[SampleStrategy alloc] init];
        
		//register for change in settings
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginChanged) name:CSsettingLoginChangedNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(generalSettingChanged:) name:[CSSettings settingChangedNotificationNameForType:kCSSettingTypeGeneral] object:nil];
	}
	return self;
}

-(void) start{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"userLoggedIn"] == YES) {
        // User is already loggedin, renew session-ID and reinitialize DSE
        NSLog(@"---SensorStore initialization. Already logged in.");
        [self loadCreadentialsFromSettingsIntoSender];
        NSError* error = nil;
        [self loginWithCompleteHandler: ^{} failureHandler:^{[CSSensePlatform logout];} andError: &error];
        
    }else{
        NSLog(@"---SensorStore initialization. Not logged in yet");
        //TODO: Do something?
    }
}

- (BOOL) loginWithUser:(NSString*) user andPassword:(NSString*) password completeHandler:(void (^)()) successHandler failureHandler:(void (^)()) failureHandler andError:(NSError **) error {
    [[CSSettings sharedSettings] setLogin:user withPassword:password];
    
    return [self loginWithCompleteHandler:successHandler failureHandler:failureHandler andError:error];
}



- (BOOL) loginWithCompleteHandler:(void (^)()) successHandler failureHandler:(void (^)()) failureHandler andError:(NSError **) error{
    BOOL succeed = [self.sender loginWithError:error];
    if (*error) {
        NSLog(@"Error during login: %@", *error);
    }
    if (succeed) {
        NSString* sessionId = [self.sender getSessionId];
        NSString* userId = [self.sender getUserId];
        NSString* appKey = self.sender.applicationKey;
        [self updateDSEWithSessionId:sessionId andUserId:userId andAppKey:appKey completeHandler:successHandler failureHandler:failureHandler];
        
        [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense value:kCSSettingYES];
    }
    return succeed;
}

- (NSArray*) getAllSensorClassesArray{
    return [NSArray arrayWithObjects:
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
}



- (void) updateDSEWithSessionId: (NSString*) sessionId andUserId:(NSString*) userId andAppKey:(NSString*) appKey completeHandler: (void (^)()) success failureHandler: (void (^)()) failure{
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
    
    if ([dse getStatus] != DSEStatusINITIALIZED) {
        [self initializeDSEWithSuccessHandler:success failureHandler: failure];
    }
}

- (void) initializeDSEWithSuccessHandler:(void (^)()) success failureHandler: (void (^)()) failure{
    // Set up callbacks
    void (^successHandler)() = ^(){NSLog(@"successcallback");
        [self onDSEInitializationSuccessWithHandler:success];
    };
    
    void (^failureHandler)(enum DSEError) = ^(enum DSEError error){
        NSLog(@"Error:%ld", (long)error);
        failure();
    };
    
    DSECallback *callback = [[DSECallback alloc] initWithSuccessHandler: successHandler
                                                      andFailureHandler: failureHandler];
    DataStorageEngine* dse = [DataStorageEngine getInstance];
    [dse setInitializationCallback:callback];
    [dse setSensorCreationHandler: ^(NSString* sensorName){
        NSLog(@"---- sensor creation Handler is triggered.");
        [self configureSensor: sensorName];
    }];
    
    // DSE go!
    NSError* error = nil;
    [dse startAndReturnError:&error];
    if (error){
        NSLog(@"Error: %@",error);
        return;
    }
}

-(void) onDSEInitializationSuccessWithHandler: (void (^)())success {
    //set settings and initialise sensors
    if (dispatch_get_current_queue() == dispatch_get_main_queue()) {
        [self instantiateSensors];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^() {
            [self instantiateSensors];
        });
    }
    [self applyGeneralSettings];
    success();
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
            }
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

-(void) configureSensor: (NSString*) sensorName{
    NSError* error = nil;
    DataStorageEngine* dse = [DataStorageEngine getInstance];
    Sensor* sensor = [dse getSensor:CSSorceName_iOS sensorName:sensorName error:&error];
    NSDictionary* sensorOptions = [self getDefaultSensorOptionForSensor:sensor.name];
    if (sensorOptions != nil){
        NSError* error = nil;
        SensorConfig* config = [[SensorConfig alloc] init];
        config.uploadEnabled = [sensorOptions[@"upload_enabled"] boolValue];
        config.downloadEnabled = [sensorOptions[@"download_enabled"] boolValue];
        config.persist = [sensorOptions[@"persist_locally"] boolValue];
        [sensor setSensorConfig:config error:&error];
    }
}

- (NSDictionary*) getDefaultSensorOptionForSensor:(NSString*) sensorName{
    // get default sensor options from json file
    NSError* error = nil;
    NSString *filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"default_sensor_options" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSArray* arrayOfSensorOptions = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    // find the corresponding one
    for(NSDictionary* sensorOptions in arrayOfSensorOptions){
        if([sensorOptions[@"sensor_name"] isEqualToString: sensorName]){
            return sensorOptions;
        }
    }
    return nil;
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
        [self forceDataFlushWithSuccessCallback:^{} failureCallback:^(NSError* error){}];
        
        //set timer
        //[self stopUploading];
	} else {
        //send notifications to notify sensors whether they should activate themselves
        for (CSSensor* sensor in sensors) {
			[[CSSettings sharedSettings] sendNotificationForSensor:sensor.name];
        }
        //enable uploading
        //[self setSyncRate:syncRate];
	}
        
    waitTime = 0;
    }
}

- (void) loginChanged {
	//flush current data before making any changes
	//[self forceDataFlush];
	
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




- (void) applyGeneralSettings {
	@try {
        [self loadCreadentialsFromSettingsIntoSender];

        //TODO:FIX
		NSString* setting = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval];

        if ([setting isEqualToString:kCSGeneralSettingUploadIntervalAdaptive]){
            [self setSyncInterval:10];
//            [self setSyncRate:10];
        } else if ([setting isEqualToString:kCSGeneralSettingUploadIntervalNightly]){
            [self setSyncInterval:3600];
//            [self setSyncRate:3600];
        } else if ([setting isEqualToString:kCSGeneralSettingUploadIntervalWifi]){
            [self setSyncInterval:3600];
//            [self setSyncRate:3600];
        }else if ([setting doubleValue]) {
            [self setSyncInterval:MAX(1,[setting doubleValue])];
//            [self setSyncRate:MAX(1,[setting doubleValue])];
        } else {
            [self setSyncInterval:1800];
//            [self setSyncRate:1800]; //Hmm, unknown, let's choose some value
        }
        
		[self setEnabled:[[[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingSenseEnabled] boolValue]];
	}
	@catch (NSException * e) {
		NSLog(@"SenseStore: Exception thrown while updating general settings: %@", e);
	}	
}

- (void)loadCreadentialsFromSettingsIntoSender{
    //get settings
    NSString* username = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUsername];
    NSString* passwordHash = [[CSSettings sharedSettings] getSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingPassword];
    //apply properties one by one
    [sender setUser:username andPasswordHash:passwordHash];
}



- (void) forceDataFlushWithSuccessCallback: (void(^)()) successCallback failureCallback:(void(^)(NSError*)) failureCallback {
    //flush to disk before uploading. In case of a flush we want to make sure the data is saved, even if the app cannot upload.
    void (^successHandler)() = ^(){
        successCallback();
        NSLog(@"Flush completed");
    };
    
    void (^failureHandler)(enum DSEError) = ^(enum DSEError error){
        failureCallback(nil);
        NSLog(@"Error:%ld", (long)error);
    };
    
    DSECallback *callback = [[DSECallback alloc] initWithSuccessHandler: successHandler
                                                      andFailureHandler: failureHandler];
    
    
    [[DataStorageEngine getInstance] syncData:callback];
}

- (void) generalSettingChanged: (NSNotification*) notification {
	if ([notification.object isKindOfClass:[CSSetting class]]) {
		CSSetting* setting = notification.object;
		if ([setting.name isEqualToString:kCSGeneralSettingUploadInterval]) {
            
            if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalAdaptive]){
                [self setSyncInterval:10];
            } else if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalNightly]){
                [self setSyncInterval:3600];
            }else if ([setting.value isEqualToString:kCSGeneralSettingUploadIntervalWifi]){
                [self setSyncInterval:3600];
            }else if ([setting.value doubleValue]) {
                [self setSyncInterval:MAX(1,[setting.value doubleValue])];
            } else {
                [self setSyncInterval:1800];
            }
		} else if ([setting.name isEqualToString:kCSGeneralSettingSenseEnabled]) {
			[self setEnabled:[setting.value boolValue]];
		} else if ([setting.name isEqualToString:kCSGeneralSettingBackgroundRestarthack]) {
            [self setBackgroundHackEnabled:[setting.value isEqualToString:kCSSettingYES]];
        }
	}
}

- (void) setSyncInterval:(int) interval{
    DataStorageEngine* dse = [DataStorageEngine getInstance];
    DSEConfig* config = [[DSEConfig alloc] init];
    config.syncInterval = interval;
    NSError* error = nil;
    [dse setup:config error:&error];
}


- (void) setBackgroundHackEnabled:(BOOL) enable {
	//when only enabling the locationProvider and not the locationSensor the location updates are used for background monitoring but are not stored
	locationProvider.isEnabled = YES;
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

