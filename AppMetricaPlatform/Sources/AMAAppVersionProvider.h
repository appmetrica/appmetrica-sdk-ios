
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@interface AMAAppVersionProvider : NSObject<AMABundleInfoProvider>

- (instancetype)initWithBundle:(NSBundle *)bundle;

@end
