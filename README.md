\mainpage
Sense iOS platform library
=================
Sense library for sensing and using Common Sense.

##Installation
The project is setup as a static library. That means you can either compile the project and link against it, or add it as a cross-reference project in Xcode. The latter is explained here.

1. make sure you haven't opened the library project in xcode (not even as a sub project in another project) and open your own project
2. drag the libraries .xcodeproject file on top of your own project in xcode
3. add the library target as a target dependency
4. add the library to "Link binary with libraries"
5. Include at least the following frameworks in "Link binary with libraries"
 - CoreLocation
 - CoreMotion
 - CoreAudio
 - AVFoundation
 - AudioToolbox
 - CoreTelephony
 - SystemConfiguration
6. Make sure xcode can find the header files by adding the path to "Build settings"->"User header search path"
7. Add the following two resources from the resources directory in the library project to your project
 - CommonSense.plist
 - Settings.plist
8. Add the '-ObjC' and '-load_all' flag to your linker flags (see https://developer.apple.com/library/mac/#qa/qa2006/qa1490.html)
9. in your delegate at startup put [SensePlatform initialize];
10. in your delegate's willTeminate add [SensePlatform willTerminate];

Apple only allows applications to sense in the background if the position sensor is enabled (doesn't matter what accuracy).
To do that enable the sensor, but also make sure that you add to your -info.plist file the UIBackgroundModes:
"App registers for location updates" and if you're using the noise sensor also add "App plays audio".

##Examples

    Settings* settings = [Settings sharedSettings];
    [SensePlatform loginWithUser:username.text andPassword:password.text];
    [settings setSettingType:kSettingTypeSpatial setting:kSpatialSettingInterval value:@"60"];
    [settings setSettingType:kSettingTypeAmbience setting:kAmbienceSettingInterval value:@"60"];
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingUploadInterval value:@"900"];
    
    [settings setSensor:kSENSOR_BATTERY enabled:YES];
    [settings setSensor:kSENSOR_NOISE enabled:YES];
    [settings setSensor:kSENSOR_ACCELEROMETER enabled:YES];
    [settings setSensor:kSENSOR_ACCELERATION enabled:YES];
    [settings setSensor:kSENSOR_ORIENTATION enabled:YES];
    [settings setSensor:kSENSOR_ROTATION enabled:YES];
    [settings setSensor:kSENSOR_MOTION_ENERGY enabled:YES];
    
    [settings setSettingType:kSettingTypeGeneral setting:kGeneralSettingSenseEnabled value:kSettingYES];
    
    NSArray* data = [SensePlatform  getDataForSensor:@"Location" onlyFromDevice:NO nrLastPoints:5];
    
    NSDate* to = [NSDate date];
    NSDate* from = [to dateByAddingTimeInterval:-3600];
    
    [SensePlatform giveFeedbackOnState:@"Location" from:from to:to label:@"Work"];
