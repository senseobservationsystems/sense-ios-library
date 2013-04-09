//
//  Formatting.c
//  SensePlatform
//
//  Created by Pim Nijdam on 4/2/13.
//
//

#import "Formatting.h"

NSNumber* CSroundedNumber(double number, int decimals) {
    return [NSNumber numberWithDouble:round(number * pow(10,decimals)) / pow(10,decimals)];
}