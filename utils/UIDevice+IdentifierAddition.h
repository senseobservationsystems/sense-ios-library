#import <UIKit/UIKit.h>

@interface UIDevice (CSIdentifierAddition)
- (NSString *) uniqueDeviceIdentifier;

- (NSString *) uniqueGlobalDeviceIdentifier;
@end
