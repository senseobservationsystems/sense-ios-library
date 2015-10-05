//
//  TimeZoneSensor.h
//  SensePlatform
//
//  Created by Pim Nijdam on 12/11/14.
//
//

#import "CSSensor.h"

/**
 Sensor that stores the timezone the phone is set up to be in. Normally the phone automatically detects new timezones. The user can override this behavior with manual timezone setting. In that case, the sensor stores the manually set timezone. 

 ___JSON output value format___
 
	 {
		 "offset": INTEGER;
		 "id": STRING;
	 }
*/
@interface CSTimeZoneSensor : CSSensor

@end
