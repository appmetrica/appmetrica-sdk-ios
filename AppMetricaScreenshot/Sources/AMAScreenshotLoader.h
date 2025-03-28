#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMAScreenshotLoader : NSObject<AMAReporterStorageControlling, AMAExtendedStartupObserving>
+ (instancetype)sharedInstance;
@end

NS_ASSUME_NONNULL_END
