User management interface functions are provided in CSSensePlatform.h. Note that the user management settings are managed by CSSensePlatform so there is no need to change them manually (although you could, it might mess things up if you don’t know what you are doing).

First, note that a user is not strictly necessary for the library to be used. The sampling 
functionality and local storage can be used without using the app. Users are currently only necessary to be able to upload data to a commonsense account for storage in the cloud. 

<b>Warning</b><br>
Local persistency is currently not user specific. Hence, when a user logs out, the database should be cleared manually to make sure a future user on the same device does not interact with the previous user’s data.


See CSSensePlatform.h for more details.