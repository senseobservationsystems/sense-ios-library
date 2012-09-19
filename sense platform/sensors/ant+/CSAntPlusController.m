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

#import "CSAntPlusController.h"
#import "FootpodSensor.h"
#import "SensorStore.h"
#import <WFConnector/WFHardwareConnector.h>
#import <WFConnector/WFAntFS.h>
#import <WFConnector/WFAntFileManager.h>
#import <WFConnector/WFFitFileInfo.h>

#define DBG_LOG(x) [self logString:[NSString stringWithFormat:x]]

@interface AntPlusController (Private)
- (void) connectSensorType:(WFSensorType_t) sensorType;
- (void) scan;
@end

@implementation CSAntPlusController {
    WFBloodPressureManager* bpm;
    WFHardwareConnector* hardwareConnector;
    NSMutableArray* sensors;
    NSTimer* scanTimer;
}

- (id) initWithTextView:(UITextView*) tv {
    self = [super init];
    if (self) {
        textView = tv;
        // configure the hardware connector.
        hardwareConnector = [WFHardwareConnector sharedConnector];
        hardwareConnector.delegate = self;
        hardwareConnector.sampleRate = 1;
        hardwareConnector.autoReset = YES;
        sensors = [[NSMutableArray alloc] init];
        // determine support for BTLE.
        if ( hardwareConnector.hasBTLESupport ) {
            // enable BTLE.
            [hardwareConnector enableBTLE:TRUE];
        }
        [self logString:[NSString stringWithFormat:@"%@", hardwareConnector.hasBTLESupport?@"DEVICE HAS BTLE SUPPORT":@"DEVICE DOES NOT HAVE BTLE SUPPORT"]];
        // set HW Connector to call hasData only when new data is available.
        [hardwareConnector setSampleTimerDataCheck:YES];
    }
    return self;
}



- (void) connectSensorType:(WFSensorType_t) sensorType {
    WFConnectionParams* params = [[WFConnectionParams alloc] init];
    params.sensorType = sensorType;
    
    WFSensorConnection* sensorConnection;
    sensorConnection = [hardwareConnector requestSensorConnection:params];
}

- (void)hardwareConnector:(WFHardwareConnector*)hwConnector connectedSensor:(WFSensorConnection*)connection
{
    NSLog(@"Sensor connected: %@", connection.deviceIDString);
    //create new sensor
    if (connection.sensorType == WF_SENSORTYPE_FOOTPOD) {
        FootpodSensor* s = [[FootpodSensor alloc] initWithConnection:connection];
        s.dataStore = [SensorStore sharedSensorStore];
        [sensors addObject:s];
        
    } else if (connection.sensorType == WF_SENSORTYPE_ANT_FS) {
        NSLog(@"ANT FS connected !!!! Hurray hurray hurray!");
    }
}

//--------------------------------------------------------------------------------
- (void)hardwareConnector:(WFHardwareConnector*)hwConnector disconnectedSensor:(WFSensorConnection*)connectionInfo
{
    NSLog(@"Sensor disconnected %@: %@", connectionInfo.deviceIDString, connectionInfo.description);
    
}

//--------------------------------------------------------------------------------
- (void)hardwareConnector:(WFHardwareConnector*)hwConnector stateChanged:(WFHardwareConnectorState_t)currentState
{
    BOOL connected = ((currentState & WF_HWCONN_STATE_ACTIVE) || (currentState & WF_HWCONN_STATE_BT40_ENABLED)) ? TRUE : FALSE;
    NSLog(@"connector %@", connected ? @"present" : @"not present");
    [scanTimer invalidate];
    scanTimer = nil;
    if (connected) {
        //scanTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(scan) userInfo:nil repeats:YES];
        //[self scan];
    }
    [self logString:connected ? @"connector is present" : @"connector is not present"];
}

- (void) scan {
    [self logString:@"scan"];
    //TODO: create manual to scan for devices, and automatically connect to devices we've connected to in the past?
    WFSensorType_t sensorTypes[] = {};
    size_t nrSensorTypes = sizeof(sensorTypes) / sizeof(sensorTypes[0]);
    for (int i = 0; i < nrSensorTypes; i++) {
        WFSensorType_t sensorType = sensorTypes[i];
        //already have a connection to such a sensor
        if ([[hardwareConnector getSensorConnections:sensorType] count] > 0) {
            //skip
        } else {
            [self connectSensorType:sensorType];
        }
        /*
         else if ([[Settings sharedSettings] isSensorEnabled:[FootpodSensor class]]){ 
         //try to connect to such a sensor
         [self connectSensorType:sensorType];
         }
         */
    }
    if (NO) {
        //[self connectToBloodPressure];
        //[bpm requestDirectoryInfo];
        //skip
    } else {
        //try to connect to an ant fs device
        //if (bpm != nil)
        //    [hardwareConnector releaseAntFSDevice:bpm];
        [hardwareConnector requestAntFSDevice: WF_ANTFS_DEVTYPE_BLOOD_PRESSURE_CUFF
                                   toDelegate:	self];
    }
}

- (void)hardwareConnectorHasData
{
    NSLog(@"connector has data. %d sensors", sensors.count);
    for (FootpodSensor* sensor in sensors) {
        [sensor checkData];
    }
}

- (void) connectToBloodPressure {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSArray* passArray = [defaults arrayForKey:@"antPass"];

    if (passArray == nil || [passArray isKindOfClass:[NSArray class]] == NO) {
        NSNumber* zero = [NSNumber numberWithChar:0];
        passArray = [NSArray arrayWithObjects:zero, zero, zero, zero, nil];
    }
    UCHAR pass[[passArray count]];
    for (int i=0; i < [passArray count]; i++) {
        pass[i] = [[passArray objectAtIndex:i] charValue];
    }
    NSLog(@"Trying to connect with pass %@", passArray);
    [self logString:[NSString stringWithFormat:@"Trying to connect with pass %@", passArray]];
    [bpm connectToDevice:pass passkeyLength:[passArray count]];
}

- (void) syncTime {
    [bpm setDeviceTime];
}

- (void) getDirectoryInfo {
    [self logString:@"get directory info"];
    [bpm requestDirectoryInfo];
}

//implement the WFAntFSDelegate

- (void) antFSDevice:(WFAntFSDevice *) fsDevice instanceCreated:(BOOL) 	bSuccess {
    NSLog(@"ant fs device instance created. %@", bSuccess ? @"succeed" : @"failed");
    
    if (true) {
        bpm = (WFBloodPressureManager*) fsDevice;
        NSLog(@"Connected to bloodpressure monitor with serial number %lui", bpm.clientSerialNumber);
        [self logString:@"Created blood pressure monitor device"];
        [self connectToBloodPressure];
    }
}

- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       downloadFinished:		(BOOL) 	bSuccess
               filePath:		(NSString *) 	filePath {
    [self logString:[NSString stringWithFormat:@"Got file %@", filePath]];
    BOOL wtf = NO;
    NSArray* records = [bpm getFitRecordsFromFile:filePath cancelPointer:&wtf];

    for (NSObject* o in records) {
        [self logString:[NSString stringWithFormat:@"Record of type: %@",o.class]];
        if ([o isKindOfClass:WFFitMessageBloodPressure.class]) {
        WFFitMessageBloodPressure* record = (WFFitMessageBloodPressure*)o;
        USHORT heartRate = record.heartRate;
        USHORT diastollicPressure = record.diastolicPressure;
        USHORT systollicPressure = record.systolicPressure;
        NSTimeInterval timestamp = [record.timestamp timeIntervalSince1970];
        [self logString:[NSString stringWithFormat:@"Record at %.0f. Contains (%u, %u, %u)",timestamp, (unsigned int)heartRate, (unsigned int)systollicPressure, (unsigned int)diastollicPressure]];
        }
    }
    
    [self logString:[NSString stringWithContentsOfFile:filePath]];
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
    
    [self logString:log];
    
    int i=2;
    ULONG size = [directoryInfo entryAtIndex:i]->ulFileSize;
    [antFileManager requestFile:i fileSize: size];
}


- (void) antFileManager:		(WFAntFileManager *) 	antFileManager
       receivedResponse:		(ANTFS_RESPONSE) 	responseCode {
    NSLog(@"received response %i (%@)", responseCode, [self stringFromReturnCode:responseCode]);
    [self logString:[NSString stringWithFormat:@"from %ld received response %i (%@)", antFileManager.clientSerialNumber, responseCode, [self stringFromReturnCode:responseCode]]];

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
    [self logString:[NSString stringWithFormat:@"update password '%@'", passString]];
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pass forKey:@"antPass"];
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

- (void) logString:(NSString*) string {
    NSLog(@"%@",string);
    NSMutableString* text = [[NSMutableString alloc] initWithString:textView.text];
    [text appendString:string];
    [text appendString:@"\n"];
    textView.text = text;
    [textView scrollRangeToVisible:NSMakeRange([text length], 0)];
}

@end

#endif