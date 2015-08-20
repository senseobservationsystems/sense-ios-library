//
//  DSEErrors.h
//  SensePlatform
//
//  Created by Joris Janssen on 18/08/15.
//
//

static NSString *DataStorageEngineErrorDomain = @"nl.sense.DataStorageEngine.ErrorDomain";

/* List of error codes used by the DataStorageEngine */
static const int kErrorCodeInvalidUsernamePassword	= 401;
static const int kErrorInvalidInputParameters		= 402;


/* List of exception identifiers */
static NSString *kExceptionInvalidInput				= @"InvalidInputParameters";