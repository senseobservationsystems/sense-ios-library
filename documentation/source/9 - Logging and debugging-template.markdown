## Logging sensor

Upon initialization, the library will create (if not exist already) a sensor called app_info. 
It will then add a data point that contains :

* app_name (CFBundleDisplayName)
* app_version (CFBundleIdentifier)
* buildVersion (CFBundleVersion)
* locale
* OS
* OS version

This is a good source of information to know which version of the library the app is running and also if there is update.

## Logging output

The library also generate log (via NSLog) on the following event:

* Enabling / disabling sensor
* Some settings changed
* Exception
* HTTP Request
* Some sensor also provide more verbose information.

## Checking and Visualizing the data

If data upload to CommonSense is enabled. You can view the the data remotely via CommonSense Interface which is available on [https://common.sense-os.nl](https://commmon.sense-os.nl). In the web-app, you can 

* List all sensors available
* Visualize (graph, table) sensor data and specify a time range
* Share the sensor to other user
* Visualize data for multiple sensor in one graph.

CommonSense also expose a lot of functionalities with through API. Example if you would like to export your data to your computer or integrate with another service. The Documentation of the CommonSense API is available at [http://developer.sense-os.nl](http://developer.sense-os.nl).
