//
//  AntDevicesWahooDongle.h
//  sensePlatform
//
//  Created by Pim Nijdam on 3/30/12.
//  Copyright (c) 2012 Almende B.V. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFConnector/WFConnector.h>
#import <WFConnector/WFAntFs.h>

@interface AntPlusController : NSObject <WFHardwareConnectorDelegate, WFAntFSDeviceDelegate> {
    UITextView* textView;
}


//DEBUG API
- (id) initWithTextView:(UITextView*) tv;
- (void) connectToBloodPressure;
- (void) scan;
- (void) getDirectoryInfo;
- (void) syncTime;
@end
