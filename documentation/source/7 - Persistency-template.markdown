Persistency is handled both locally and remotely. 

## Local persistency

Local persistency is provided for settings and for sensor data. Settings are stored in a file as a dictionary. Whenever the library gets started the old settings are loaded and with each updated setting, they are stored again. Note that when the app is removed, the settings file is also removed. If no settings file is found, the default settings are loaded and stored. See CSSettings.h for further information.

Sensor data is stored in an SQLite table and can be retrieved by sensor and date. See CSSensePlatform.h for further information on retrieving stored data. 

There are a few limitations on the storage:

- It is kept for 30 days. Data older than 30 days is removed. 
- A maximum of 100 mb is kept. Users are likely to remove the app if there would be more storage space used. This should normally be ample for 30 days of data.
- The total amount of storage is limited if the disk space of the device is smaller than what is needed by the.
These limitations are treated in a first in first out way. Hence, older data is removed first. 

<b>Warning</b><br>
Both settings and sensordata are not stored in a user specific format. Hence, when the user logs out or the app starts to being used by a different user on the same device, the old settings and data remains accessible to the new user. 


## Remote persistency

When a user is logged in and the setting to upload to commonsense is not disabled, data will also be uploaded regularly to the commonsense cloud. From there, it can be fetched by other applications or by the same applications later on. To learn more about the remote persistency we invite the reader to dive into the documentation at developer.sense-os.nl.  

Data can be retrieved by using the standard interface function in CSSensePlatform. See CSSensePlatform.h for further information on retrieving data from the cloud.