## Installation

The xcode project is setup as a static library. That means you can either compile the project and link against it, or add it as a cross-reference project in Xcode. The latter is explained below. See also this apple keynote.

1. Download the latest released library from GitHub.
2. Make sure the library project is not opened in Xcode (not even as a sub project in another project), open your project and drag the library's .xcodeproject file on top of your own project in xcode
3. Add the library target to the "Target dependencies". Select your project in the project navigator, select your target and go to the tab "Build phases". In "Target Dependencies" add the Sense Platform
4. Add the library to "Link binary with libraries": This can be done in "Build phases"->"Link binary with libraries".
5. Include at least the following frameworks in "Link binary with libraries"
	* CoreLocation
 	* CoreMotion
 	* CoreAudio
 	* AVFoundation
 	* AudioToolbox
 	* CoreTelephony
 	* SystemConfiguration
6. Add the `-ObjC` and `-all_load` flag to your linker flags (see the Apple guide)
7. In your delegate at startup put `[CSSensePlatform initialize];` and the necesarry import: `#import <SensePlatform/CSSensePlatform.h>`
8. In your delegate's willTeminate add `[CSSensePlatform willTerminate]`;

The sense library is allowed to run in background mode only if it is using Apple’s location services.
Apple only allows applications to sense in the background if the position sensor is enabled, it does not matter with what accuracy. 
To do this, enable the location sensor `[[CSSettings sharedSettings] setSensor kCSSENSOR_LOCATION enabled:YES];`,
and also add to your `info.plist` file the `UIBackgroundModes`:

* "App registers for location updates" 
* and if you are using the noise sensor also add "App plays audio".

## Using the library
Below you will find some examples for using the library for common tasks.

### Initialization

	- (void) initExample {
	
     	//Use the settings singleton to change the settings for sensors
    	CSSettings* settings = [CSSettings sharedSettings];

    	//Set the credentials to log in to CommonSense with an existing account
    	[CSSensePlatform loginWithUser:@"username" andPassword:@"password"];
	
    	//Some settings
    	//Set location accuracy to 100 meters
    	[settings setSettingType:kCSSettingTypeLocation setting:kCSLocationSettingAccuracy value:@"100"];

    	//sample every 60 seconds the motion sensors
    	[settings setSettingType:kCSSettingTypeSpatial setting:kCSSpatialSettingInterval value:@"60"];

    	//sample every 60 seconds the ambience sensors.
    	[settings setSettingType:kCSSettingTypeAmbience setting:kCSAmbienceSettingInterval value:@"60"];

    	//Upload every 15 minutes to CommonSense
    	[settings setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingUploadInterval value:@"900"];
	
    	//Enable some sensors
    	//Need the location sensor to run in the background
    	[settings setSensor:kCSSENSOR_LOCATION enabled:YES];
    	[settings setSensor:kCSSENSOR_BATTERY enabled:YES];
    	[settings setSensor:kCSSENSOR_NOISE enabled:YES];
    	[settings setSensor:kCSSENSOR_ACCELEROMETER enabled:YES];
	
    	//Listen to data from the sensors
    	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newData:) name:kCSNewSensorDataNotification 	object:nil];
	
    	//Use this to enable/disable the whole sense platform
    	[settings setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingSenseEnabled value:kCSSettingYES];
	}

### Getting data from the library
	- (void) getDataExample {
	    //Retrieve the last 5 data points from the Location sensor, the sensor doesn't have to be associated with this device
	    NSArray* data = [CSSensePlatform  getDataForSensor:@"Location" onlyFromDevice:NO nrLastPoints:5];
	}

### Listening to new sensor data
	- (void) newData:(NSNotification*)notification {
	    NSString* sensor = notification.object;
	    //Look for battery sensor
	    if ([sensor isEqualToString:kCSSENSOR_BATTERY]) {
	        //extract value
	        NSDictionary* data = [[notification.userInfo objectForKey:@"value"] JSONValue];    
	    }    
	}



If you would like to understand a bit more about how to use the app, please read API and Architecture overview. 
