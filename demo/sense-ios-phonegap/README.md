This is a demo project that uses Sense platform from within
[PhoneGap](http://phonegap.com/) version 2.6.0. 

The project was created following [PhoneGap's
guide](http://docs.phonegap.com/en/2.6.0/guide_getting-started_ios_index.md.html).
The Sense library was added by following the [Sense library
tutorial](http://developer.sense-os.nl/Libraries/iOS/).
Next the Sense Phonegap plugin need to be added to the project so it will be build. The files "sense platform/plugins/CSPGSensePlatform.[hm]" were added to the demo project.

At this point the project uses default PhoneGap example and the Sense library
is exposed as a plugin called CSPGSensePlatform. The javascript bindings for
this plugin are located in www/sense_plaform.js.

Next the SenseCordovaDemo/config.xml was modified to whitelist all network
domains and the Sense plugin was added. The default page was pointed to
www/sense_example.html which contains a full example to use the Sense plugin.

In order to create your own PhoneGap Sense project you can clone this project
and put your html/css/javascript files in the www directory.

 - Load the sense_platform.js file in your HTML. You can find in inside the
   /www folder.
 - The Sense platform methods are now accessible in JavaScript through
   window.plugins.sense.*.
 - When starting you app, make sure that you call window.plugins.sense.init()
   to initialize the plugin. A good place for this would be right after the
deviceready event that PhoneGap features.
