//
//  CSUploader.h
//  SensePlatform
//
//  Created by Pim Nijdam on 14/04/14.
//
//

#import <Foundation/Foundation.h>
#import "CSStorage.h"
#import "CSSender.h"

/** Uploads data to CommonSense */
@interface CSUploader : NSObject
- (id) initWithStorage:(CSStorage*) theStorage andSender:(CSSender*) theSender;

/**
 Upload all data that has not been uploaded yet to CommonSense server. The function will fetch remote sensor IDs from the server and try to match them up with local sensors. If there is a local sensor that cannot be matched to a remote sensor it will create a new remote sensor for the sensordata. If it cannot fetch the remote sensor IDs it will return NO without uploading. 
 
 @return Whether or not the upload was successful
 */
- (BOOL) upload;


- (long long) lastUploadedRowId;
@end
