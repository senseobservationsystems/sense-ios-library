//
//  CSActivityProcessorSensor.h
//  SensePlatform
//
//  Created by Pim Nijdam on 02/06/14.
//
//

#import "CSSensor.h"

/**
 Sensor that stores the activity detection value provided by iOS. 
 
 ___JSON output value format___

	 {
		"confidence": STRING; // "low", "medium", "high", "unknown"
		"activity": STRING; // "unknown", "idle", "walking", "running", "automotive"
	 }
 */
@interface CSActivityProcessorSensor : CSSensor

@end
