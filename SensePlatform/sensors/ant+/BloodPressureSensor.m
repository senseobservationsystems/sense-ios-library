/* Copyright (©) 2012 Sense Observation Systems B.V.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Author: Pim Nijdam (pim@sense-os.nl)
 */
#if 0

#import "BloodPressureSensor.h"
#import "DataStore.h"
#import <WFConnector/WFHardwareConnector.h>
#import <WFConnector/WFAntFS.h>
#import <WFConnector/WFAntFileManager.h>
#import <WFConnector/WFFitFileInfo.h>
#import "SensePlatform.h"
#import "JSON.h"

#import <UIKit/UIkit.h>


static NSString* const heartRateKey = @"heart rate";
static NSString* const diastollicPressureKey = @"diastollic";
static NSString* const systollicPressureKey = @"systollic";
static NSString* const passKey = @"sense.ant.bpm.pass";
static NSString* const lastBloodPressureRecordKey = @"sense.ant.bpm.lastBloodPressureRecord";
static const NSTimeInterval SCAN_INTERVAL = 60;

@implementation BloodPressureSensor {
    NSDateFormatter* rfc3339DateFormatter;
    
    WFBloodPressureManager* bpm;
    WFHardwareConnector* hardwareConnector;
    NSDate* lastBloodPressureRecord;
    
    NSTimer* periodicCheckTimer;
    NSInteger tries, newRecordsFound, newMeasurementErrorsFound;
    bpmCallBack callback;
    BOOL done;
    BOOL foundDevice, authorizationFailure;
    
}

- (NSString*) name {return kSENSOR_BLOOD_PRESSURE;}
- (NSString*) deviceType {return [self name];}

+ (BOOL) isAvailable {return YES;}

- (NSDictionary*) sensorDescription {
	//create description for data format. programmer: make SURE it matches the format used to send data
	NSDictionary* format = [NSDictionary dictionaryWithObjectsAndKeys:
							kSENSEPLATFORM_DATA_TYPE_FLOAT, diastollicPressureKey,
   							kSENSEPLATFORM_DATA_TYPE_FLOAT, systollicPressureKey,
							kSENSEPLATFORM_DATA_TYPE_INTEGER, heartRateKey,
							nil];
	//make string, as per spec
	NSString* json = [format JSONRepresentation];
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self name], @"name",
			[self deviceType], @"device_type",
			@"", @"pager_type",
			@"json", @"data_type",
			json, @"data_structure",
			nil];
}



- (id) init {
    self = [super init];
    if (self) {
        //rfc3339 date formatter
        NSLocale* enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        rfc3339DateFormatter = [[NSDateFormatter alloc] init];
        [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
        [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        
        // configure the hardware connector.
        hardwareConnector = [WFHardwareConnector sharedConnector];
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSString* lastRecordDate = [defaults stringForKey:lastBloodPressureRecordKey];
        NSDate* date = [rfc3339DateFormatter dateFromString:lastRecordDate];
        if (lastRecordDate != nil && date != nil)
            lastBloodPressureRecord = date;
    }
    return self;
}

- (BOOL) isEnabled {return isEnabled;}

- (void) setIsEnabled:(BOOL) enable {
    //do nothing, this sensor should be explicitely invoked
}

- (void) syncMeasurements:(bpmCallBack) cb {
	//only react to changes
    NSLog(@"sync measurements");
    
    if (periodicCheckTimer) {
        [periodicCheckTimer invalidate];
        periodicCheckTimer = nil;
    }
    
    callback = cb;
    if (NO == hardwareConnector.isFisicaConnected) {
        NSLog(@"No connector");
        callback(BPM_CONNECTOR_NOT_PRESENT, 0, 0, lastBloodPressureRecord);
    }

    bpm = nil;
    tries = 1;
    newRecordsFound = 0;
    newMeasurementErrorsFound = 0;
    done = false;
    foundDevice = NO;
    authorizationFailure = NO;

    periodicCheckTimer = [NSTimer scheduledTimerWithTimeInterval:SCAN_INTERVAL target:self selector:@selector(scan) userInfo:nil repeats:YES];
    [self scan];
}


- (void) scan {
    if (done == NO && tries>0) {
        tries--;
        //if (bpm != nil) {
            [hardwareConnector requestAntFSDevice: WF_ANTFS_DEVTYPE_BLOOD_PRESSURE_CUFF
                                   toDelegate:	self];
        //}
    } else if (done == NO){
        //we should be done, measurement failed
        bpm = nil;
        if (periodicCheckTimer != nil) {
            [periodicCheckTimer invalidate];
            periodicCheckTimer = nil;
        }
        
        BpmResult result = BPM_NOT_FOUND;
        if (authorizationFailure)
            result = BPM_UNAUTHORIZED;
        else if (foundDevice)
            result = BPM_OTHER_ERROR;
        if (callback != nil)
            callback(result, 0, 0, lastBloodPressureRecord);
    }
}


- (void) connectToBloodPressure {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSArray* passArray = [defaults arrayForKey:passKey];
    
    if (passArray == nil) {
        NSNumber* zero = [NSNumber numberWithChar:0];
        passArray = [NSArray arrayWithObjects:zero, zero, zero, zero, nil];
    }
    UCHAR pass[[passArray count]];
    for (int i=0; i < [passArray count]; i++) {
        pass[i] = [[passArray objectAtIndex:i] charValue];
    }
    NSLog(@"Trying to connect with pass %@", passArray);
    [bpm connectToDevice:pass passkeyLength:[passArray count]];
}

- (void) syncTime {
    [bpm setDeviceTime];
}

- (void) getDirectoryInfo {
    NSLog(@"get directory info");
    [bpm requestDirectoryInfo];
}

//implement the WFAntFSDelegate

- (void) antFSDevice:(WFAntFSDevice *) fsDevice instanceCreated:(BOOL) 	bSuccess {
    NSLog(@"ant fs device instance created. %@", bSuccess ? @"succeed" : @"failed");
    
    if (true) {
        bpm = (WFBloodPressureManager*) fsDevice;
        NSLog(@"Connected to bloodpressure monitor with serial number %lui", bpm.clientSerialNumber);
        [self connectToBloodPressure];
    }
}

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       downloadFinished:		(BOOL) 	bSuccess
               filePath:		(NSString *) 	filePath {
    if (bpm == nil)
        return;
    
    
    BOOL wtf = NO;
    NSArray* records = [bpm getFitRecordsFromFile:filePath cancelPointer:&wtf];
    
    for (NSObject* o in records) {
        if ([o isKindOfClass:WFFitMessageBloodPressure.class]) {
            WFFitMessageBloodPressure* record = (WFFitMessageBloodPressure*)o;
            USHORT heartRate = record.heartRate;
            USHORT diastollicPressure = record.diastolicPressure;
            USHORT systollicPressure = record.systolicPressure;
            NSTimeInterval timestamp = [record.timestamp timeIntervalSince1970];
            NSLog(@"Record at %.0f. Contains (%u, %u, %u)",timestamp, (unsigned int)heartRate, (unsigned int)systollicPressure, (unsigned int)diastollicPressure);
            if (lastBloodPressureRecord == nil || [record.timestamp timeIntervalSinceDate:lastBloodPressureRecord] > 0) {
                lastBloodPressureRecord = record.timestamp;
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[rfc3339DateFormatter stringFromDate:lastBloodPressureRecord] forKey:lastBloodPressureRecordKey];
                if (heartRate != 255) {
                    newRecordsFound++;
                    [self commitBloodPressureRecord:record];
                } else {
                    newMeasurementErrorsFound++;
                }
            }
        }
    }
    done = YES;
    bpm = nil;
    if (periodicCheckTimer != nil) {
        [periodicCheckTimer invalidate];
        periodicCheckTimer = nil;
    }
    
    BpmResult result = BPM_SUCCES;
    callback(result, newRecordsFound, newMeasurementErrorsFound, lastBloodPressureRecord);
}

- (void) commitBloodPressureRecord:(WFFitMessageBloodPressure*) record {

    USHORT heartRate = record.heartRate;
    USHORT diastollicPressure = record.diastolicPressure;
    USHORT systollicPressure = record.systolicPressure;
    NSTimeInterval timestamp = [record.timestamp timeIntervalSince1970];
    
    NSDictionary* value = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSString stringWithFormat:@"%i", (int) heartRate], heartRateKey,
                           [NSString stringWithFormat:@"%i", (int) systollicPressure], systollicPressureKey,
                           [NSString stringWithFormat:@"%i", (int) diastollicPressure], diastollicPressureKey,
                           nil];
    NSDictionary* timeValuePair = [NSDictionary dictionaryWithObjectsAndKeys:[value JSONRepresentation], @"value",
                                   [NSString stringWithFormat:@"%.3f", timestamp], @"date",
                                   nil];
    [dataStore commitFormattedData:timeValuePair forSensorId:self.sensorId];
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       downloadProgress:		(ULONG) 	bytesReceived {
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
  receivedDirectoryInfo:		(WFAntFSDirectory *) 	directoryInfo {
    //log directory structure
    NSMutableString* log = [[NSMutableString alloc] init];
    [log appendFormat:@"%i entries.", directoryInfo.numberOfEntries];
    
    for (size_t i =0; i < directoryInfo.numberOfEntries; i++) {
        ANTFSP_DIRECTORY* dir = [directoryInfo entryAtIndex:i];
        [log appendFormat:@"entry %i: %c, %c, size %il, fileIndex %i, fileNumber %i\n", i, dir->ucFileDataType, dir->ucFileSubType, dir->ulFileSize, (int)dir->usFileIndex, (int)dir->usFileNumber];
    }
    
    NSLog(@"%@", log);
    
    int i=2;
    ULONG size = [directoryInfo entryAtIndex:i]->ulFileSize;
    [antFileManager requestFile:i fileSize: size];
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       receivedResponse:		(ANTFS_RESPONSE) 	responseCode {
    foundDevice = YES;
    
    if (responseCode == ANTFS_RESPONSE_AUTHENTICATE_FAIL || responseCode == ANTFS_RESPONSE_AUTHENTICATE_REJECT ||
        responseCode == ANTFS_RESPONSE_DISCONNECT_BROADCAST_PASS || responseCode == ANTFS_RESPONSE_DISCONNECT_PASS ||
        responseCode == ANTFS_RESPONSE_OPEN_PASS)
        authorizationFailure = YES;
    else if (responseCode == ANTFS_STATE_CONNECTED)
        authorizationFailure = NO;
    //NSLog(@"received response %i (%@)", responseCode, [self stringFromReturnCode:responseCode]);
    
    /*
     if (responseCode == ANTFS_RESPONSE_CONNECTION_LOST) {
     [hardwareConnector releaseAntFSDevice:bpm];
     //try to connect to an ant fs device
     [hardwareConnector requestAntFSDevice: WF_ANTFS_DEVTYPE_BLOOD_PRESSURE_CUFF
     toDelegate:	self];
     }
     */
    
    /*
     if (responseCode == ANTFS_RESPONSE_OPEN_PASS || responseCode == ANTFS_RESPONSE_CONNECT_PASS) {
     [self connectToBloodPressure];
     [bpm requestDirectoryInfo];
     } else if (responseCode == ANTFS_RESPONSE_AUTHENTICATE_PASS) {
     [bpm requestDirectoryInfo];
     }
     */
} 

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
          updatePasskey:		(UCHAR *) 	pucPasskey
                 length:		(UCHAR) 	ucLength {
    NSLog(@"update pass key with length %d",(NSInteger) ucLength);
    NSMutableArray* pass = [[NSMutableArray alloc] init];
    NSMutableString *passString = [[NSMutableString alloc] init];
    for (int i = 0; i < ucLength; i++) {
        NSNumber* o = [NSNumber numberWithChar:pucPasskey[i]];
        [pass addObject:o];
        [passString appendFormat:@"%i:", [o intValue]];
        
    }
    NSLog(@"pass key: %@", passString);
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pass forKey:passKey];
    [defaults synchronize];
}

- (NSString*) stringFromReturnCode:(ANTFS_RESPONSE) responseCode {
    switch (responseCode) {
            
        case ANTFS_RESPONSE_NONE 	:
            return @"ANTFS_RESPONSE_NONE";	
        case ANTFS_RESPONSE_OPEN_PASS 	:
            return @"ANTFS_RESPONSE_OPEN_PASS";	
        case ANTFS_RESPONSE_SERIAL_FAIL 	:
            return @"ANTFS_RESPONSE_SERIAL_FAIL";	
        case ANTFS_RESPONSE_BEACON_OPEN 	:
            return @"ANTFS_RESPONSE_BEACON_OPEN";	
        case ANTFS_RESPONSE_BEACON_CLOSED 	:
            return @"ANTFS_RESPONSE_BEACON_CLOSED";	
        case ANTFS_RESPONSE_CONNECT_PASS 	:
            return @"ANTFS_RESPONSE_CONNECT_PASS";	
        case ANTFS_RESPONSE_DISCONNECT_PASS 	:
            return @"ANTFS_RESPONSE_DISCONNECT_PASS";	
        case ANTFS_RESPONSE_DISCONNECT_BROADCAST_PASS 	:
            return @"ANTFS_RESPONSE_DISCONNECT_BROADCAST_PASS";	
        case ANTFS_RESPONSE_CONNECTION_LOST 	:
            return @"ANTFS_RESPONSE_CONNECTION_LOST";	
        case ANTFS_RESPONSE_AUTHENTICATE_NA 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_NA";	
        case ANTFS_RESPONSE_AUTHENTICATE_PASS 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_PASS";	
        case ANTFS_RESPONSE_AUTHENTICATE_REJECT 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_REJECT";	
        case ANTFS_RESPONSE_AUTHENTICATE_FAIL 	:
            return @"ANTFS_RESPONSE_AUTHENTICATE_FAIL";	
        case ANTFS_RESPONSE_PAIRING_REQUEST 	:
            return @"ANTFS_RESPONSE_PAIRING_REQUEST";	
        case ANTFS_RESPONSE_PAIRING_TIMEOUT 	:
            return @"ANTFS_RESPONSE_PAIRING_TIMEOUT";	
        case ANTFS_RESPONSE_DOWNLOAD_REQUEST 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_REQUEST";	
        case ANTFS_RESPONSE_DOWNLOAD_PASS 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_PASS";	
        case ANTFS_RESPONSE_DOWNLOAD_REJECT 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_REJECT";	
        case ANTFS_RESPONSE_DOWNLOAD_INVALID_INDEX 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_INVALID_INDEX";	
        case ANTFS_RESPONSE_DOWNLOAD_FILE_NOT_READABLE 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_FILE_NOT_READABLE";	
        case ANTFS_RESPONSE_DOWNLOAD_NOT_READY 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_NOT_READY";	
        case ANTFS_RESPONSE_DOWNLOAD_FAIL 	:
            return @"ANTFS_RESPONSE_DOWNLOAD_FAIL";	
        case ANTFS_RESPONSE_UPLOAD_REQUEST 	:
            return @"ANTFS_RESPONSE_UPLOAD_REQUEST";	
        case ANTFS_RESPONSE_UPLOAD_PASS 	:
            return @"ANTFS_RESPONSE_UPLOAD_PASS";	
        case ANTFS_RESPONSE_UPLOAD_REJECT 	:
            return @"ANTFS_RESPONSE_UPLOAD_REJECT";	
        case ANTFS_RESPONSE_UPLOAD_INVALID_INDEX 	:
            return @"ANTFS_RESPONSE_UPLOAD_INVALID_INDEX";	
        case ANTFS_RESPONSE_UPLOAD_FILE_NOT_WRITEABLE 	:
            return @"ANTFS_RESPONSE_UPLOAD_FILE_NOT_WRITEABLE";	
        case ANTFS_RESPONSE_UPLOAD_INSUFFICIENT_SPACE 	:
            return @"ANTFS_RESPONSE_UPLOAD_INSUFFICIENT_SPACE";	
        case ANTFS_RESPONSE_UPLOAD_FAIL 	:
            return @"ANTFS_RESPONSE_UPLOAD_FAIL";	
        case ANTFS_RESPONSE_ERASE_REQUEST 	:
            return @"ANTFS_RESPONSE_ERASE_REQUEST";	
        case ANTFS_RESPONSE_ERASE_PASS 	:
            return @"ANTFS_RESPONSE_ERASE_PASS";	
        case ANTFS_RESPONSE_ERASE_REJECT 	:
            return @"ANTFS_RESPONSE_ERASE_REJECT";	
        case ANTFS_RESPONSE_ERASE_FAIL 	:
            return @"ANTFS_RESPONSE_ERASE_FAIL";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_PASS 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_PASS";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_TRANSMIT_FAIL 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_TRANSMIT_FAIL";	
        case ANTFS_RESPONSE_MANUAL_TRANSFER_RESPONSE_FAIL 	:
            return @"ANTFS_RESPONSE_MANUAL_TRANSFER_RESPONSE_FAIL";	
        case ANTFS_RESPONSE_CANCEL_DONE :
            return @"ANTFS_RESPONSE_CANCEL_DON"; 
            
        default:
            return @"unknown response code";
    }
}

@end

#endif