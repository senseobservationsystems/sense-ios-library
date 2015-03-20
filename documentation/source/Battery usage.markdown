As the library samples regularly in the background, there can be a significant impact on battery life of the phone while running the app. A few general heuristics can dramatically reduce battery life. Next to that, the library provides a few specific settings that can also reduce battery life when enabled.

## Guidelines

### Limit wake ups
The best way to limit the battery usage is to limit the times the app is woken up. The library wakes up for each sampling moment. Hence, when reducing the amount of sampling, this will reduce the number of wakeups, and thus will reduce battery usage. We have found that for most purposes only sampling once every 180 seconds provides enough accuracy (e.g., for activity detection). Hence, try to reduce the sample frequency to the lowest acceptable value. You can change the sample frequency by using the requirements:

    Cortex* cortex = [Cortex sharedCortex];
    NSString* consumerName = @"com.sense.cortexdemo";
    NSArray* commonRequirements = @[@{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_NOISE, kCSREQUIREMENT_FIELD_SAMPLE_INTERVAL:@10}];
    [[CSSensorRequirements sharedRequirements] setRequirements:commonRequirements byConsumer:consumerName];
	
Moreover, be careful when using timers etc in the app that might wake it up regularly. Even though the performed task might be small, simply the fact that the CPU has to wake up from idle mode has a large impact on the battery. Hence, use timers carefully and sparingly, because they will remain active when the app removes from foreground.

Finally, users are since iOS 8 informed by Apple on the amount of wake ups and CPU cycles used by the app in the form of a percentage of usage of each individual app. If your app gets woken up often, the users will likely start to complain.

### Limit server communication
Another major impact on the battery is the amount of communication with the server. Hence, trying to limit the number of times data is uploaded or fetched from CommonSense, as well as limiting the amount of data itself every update can help to reduce battery usage. 

To do this, consider carefully which sensors are necessary and which can be disabled. Especially burst-mode sensors are heavy on the data communication. Subsequently, think if data should be stored remotely at all, and if so how often it should be synced to the server. We use a default of once per hour to sync if there is internet connection, and the library already taps into existing internet connections through a leeway of 10 minutes. 


## Settings for battery usage optimization

There are three specific settings that reduce battery consumption. 

If you don’t need data remotely, disable the uploading. 

	[[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadToCommonSense value:kCSSettingNO];

If you don’t need the burst data remotely, but do need it locally, you can specify not to upload burst data.

	[[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingDontUploadBursts value:kCSSettingYES];

Location data is sampled by iOS in an event-based manner; that means the developer has no control over when to receive location data as iOS optimizes this based on the behavior of the phone and user. However, when not needing detailed location data and just having it enabled to be allowed to run in the backround mostly, we can start and stop location updates for as long as the app is allowed to run in the backrgound anyway (this is typically 3 minutes). The following setting enables this. 

	[[CSSettings sharedSettings] setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingCortexAutoPausing value:kCSSettingYES];

Use a high upload interval, like 3600 seconds (i.e., one hour).

	[[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSLocationSettingUploadInterval value:@”3600”];


<b>Note</b><br>
There is currently no central polling mechanism and the library does not use the kCSGeneralSettingPollInterval currently. This might change in the future.
