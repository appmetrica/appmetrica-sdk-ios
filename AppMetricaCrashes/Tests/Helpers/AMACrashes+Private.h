
#import "AMACrashes.h"
#import "AMACrashLoader.h"

@interface AMACrashes (Private) <AMACrashLoaderDelegate>

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;

@end

@interface AMACrashes (Test)

- (NSDictionary *)crashContext;

@end
