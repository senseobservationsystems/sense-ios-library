
In order for the library to be able to sample data it needs to run continuously in the background. This is not always allowed by Apple. Therefore, to run in the background, the app makes use of location services. 

## Make the app run in the background
The location services should be enabled by the developer. There are several ways to enable them in the library. One way is to enable one of the sensors <code>kCSSENSOR_LOCATION</code> or <code>kCSSENSORVISITS</code>

that uses the location provider by setting a requirement on it: 

 	NSString* consumerName = @"com.sense.cortexdemo";
 	NSArray* commonRequirements = @[@{@{kCSREQUIREMENT_FIELD_SENSOR_NAME:kCSSENSOR_LOCATION, kCSREQUIREMENT_FIELD_SAMPLE_ACCURACY:@10000}];
 	[[CSSensorRequirements sharedRequirements] setRequirements:commonRequirements byConsumer:consumerName];
   
This will enable that particular sensor and the location sensing to be able to run in the background. When you would not need to store the location data but just need to sample it to be able to run in the background a better solution is to enable the kCSGeneralSettingBackgroundRestarthack setting by

    [[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingBackgroundRestarthack value:kCSSettingYES];
 
Note that whenever this setting or requirement is processed the user will be asked to provide permission to use location services. 

There are than a few more steps to take into account. First, you need to add to your info.plist file the UIBackgroundModes: "App registers for location updates". Whenever you submit your app to Apple for review, you need to explain the reason for the location updates and provide a warning about battery usage. An example could be:

<blockquote>
The app enables the user to track their physical activity. For this the app accesses locations and the accelerometer sensor, hence the app declares support for location in the UIBackgroundModes.
</blockquote>

And this could be an example of a user facing disclaimer that is also required by Apple:

<blockquote>
Disclaimer: Continued use of GPS running in the background can dramatically decrease battery life. This app accesses your location to enable you to track your sleep and activity.
</blockquote>

<b>Warning</b><br>
Whenever the app crashes for some reason it does not sample data anymore. The app will restart itself on a significant location update (for this, significantLocationUpdates are turned on). However, when there is no significant location update for a while this might cause missing data and could influence the quality of subsequent processing. Hence, it is important to minimize crashes for apps using the library while running in the background. 
