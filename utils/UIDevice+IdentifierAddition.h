//
//  UIDevice+IdentifierAddition.h
//  Sense platform
//
//  Created by Pim Nijdam on 9/3/12.
//
//

#import <UIKit/UIKit.h>

@interface UIDevice (CSIdentifierAddition)
- (NSString *) uniqueDeviceIdentifier;

- (NSString *) uniqueGlobalDeviceIdentifier;
@end
