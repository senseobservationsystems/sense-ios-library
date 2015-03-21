The library uses SQLLite for storing the sensor data locally. It acts as a buffer before uploading data to CommonSense Platform.
In order to store data securely, the library support data encription by using SQLChiper library
To use it you only need to change a settings

	[[CSSettings sharedSettings] setSettingType:kCSSettingTypeGeneral setting:kCSGeneralSettingLocalStorageEncryption value: kCSSettingYES];

When this setting is enabled, the database will be locked and converted with encription. 
Any attemp to store new sensor data will block until the data migration has finished. This also the case when converting from encrypted on unencrpted

*Notice*
Using encrption will occur some overhead. Storing data will use more CPU thus will affect performance and the battery usage.
For more information about the performance please have a look at the article on [https://www.zetetic.net/blog/2011/5/7/sqlcipher-performance-and-sqlcipherspeed.html](https://www.zetetic.net/blog/2011/5/7/sqlcipher-performance-and-sqlcipherspeed.html)