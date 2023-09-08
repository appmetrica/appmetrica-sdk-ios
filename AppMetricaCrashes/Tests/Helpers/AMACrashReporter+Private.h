
#import "AMACrashReporter.h"
#import "AMACrashLoader.h"

@interface AMACrashReporter (Private) <AMACrashLoaderDelegate>

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;

@end

@interface AMACrashReporter (Test)

- (NSDictionary *)crashContext;

@end
