
#import "AMAAppMetricaCrashes.h"
#import "AMAKSCrashLoader.h"

@interface AMAAppMetricaCrashes (Private) <AMACrashLoaderDelegate>

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;

@end

@interface AMAAppMetricaCrashes (Test)

- (NSDictionary *)crashContext;

@end
