//
//  AccountUtilsForTest.h
//  SensePlatform
//
//  Created by Tatsuya Kaneko on 08/09/15.
//
//

/* Some test values */
static NSString* testAppKeyStaging = @"wRgE7HZvhDsRKaRm6YwC3ESpIqqtakeg";
static NSString* newUserEmail_format = @"spam+%f@sense-os.nl";
static NSString* testPassword = @"darkr";

static NSString* kUrlBaseURLStaging = @"http://api.staging.sense-os.nl";
static NSString* kUrlAuthenticationStaging= @"http://auth-api.staging.sense-os.nl/v1";

static const NSString* kUrlLogin					= @"login";
static const NSString* kUrlLogout                   = @"logout";
static const NSString* kUrlSensorDevice             = @"device";
static const NSString* kUrlSensors                  = @"sensors";
static const NSString* kUrlUsers                    = @"users";
static const NSString* kUrlUploadMultipleSensors    = @"sensors/data";
static const NSString* kUrlData                     = @"data";
static const NSString* kUrlDevices                  = @"devices";
static const NSString* kUrlJsonSuffix               = @"";

@interface AccountUtilsForTest : NSObject


+ (NSString *) loginUser: (NSString *) username andPassword: (NSString *) password andError: (NSError **) error;

+ (BOOL) logoutCurrentUserWithSessionID: (NSString *) sessionID andError: (NSError **) error;

+ (BOOL) registerUser:(NSString*) user withPassword:(NSString*) pass withEmail:(NSString*) email error:(NSError**) error;

+ (BOOL) deleteUserWithId:(NSString*) userId andSessionID: sessionID error:(NSError**) error;

+ (NSDictionary*) getCurrentUserWithSessionID:(NSString*) sessionID andError:(NSError**) error;

+ (NSURL*) makeUrlFor:(const NSString*) action;

+ (NSURL*) makeUrlFor:(const NSString *) action append:(NSString *) appendix;
@end