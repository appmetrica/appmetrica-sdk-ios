
#import "AMAAppMetricaCrashes.h"
#import "AMACrashLoader.h"

@interface AMAAppMetricaCrashes (Private) <AMACrashLoaderDelegate>

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error;

@end

@interface AMAAppMetricaCrashes (Test)

- (NSDictionary *)crashContext;

@end
