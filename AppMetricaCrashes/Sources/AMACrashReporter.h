#import <Foundation/Foundation.h>
#import "AMAAppMetricaCrashReporting.h"
#import "AMAAppMetricaPluginReporting.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMAAppMetricaReporting;
@class AMAEventPollingParameters;
@class AMAErrorEnvironment;

extern NSString *const kAppMetricaLibraryAPIKey;

@interface AMACrashReporter : NSObject <AMAAppMetricaCrashReporting, AMAAppMetricaPluginReporting>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithApiKey:(NSString *)apiKey;
- (instancetype)initWithApiKey:(NSString *)apiKey
              errorEnvironment:(AMAErrorEnvironment *)errorEnvironment;

- (void)reportCrashWithParameters:(AMAEventPollingParameters *)parameters;
- (void)reportANRWithParameters:(AMAEventPollingParameters *)parameters;

- (void)reportInternalError:(NSError *)error;
- (void)reportInternalCorruptedCrash:(NSError *)error;
- (void)reportInternalCorruptedError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
