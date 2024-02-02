
#import <Foundation/Foundation.h>
#import "AMAAppMetricaPlugins.h"

@protocol AMAAppMetricaCrashReporting;

@interface AMAAppMetricaPluginsImpl : NSObject <AMAAppMetricaPlugins>

- (void)setupCrashReporter:(id<AMAAppMetricaCrashReporting>)crashReporter;

@end
