
#import <Foundation/Foundation.h>

@protocol AMAAsyncExecuting;
@class AMASearchAdsRequester;
@class AMASearchAdsReporter;
@class AMAReporterStateStorage;

@interface AMASearchAdsController : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApiKey:(NSString *)apiKey
                      executor:(id<AMAAsyncExecuting>)executor
          reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage;
- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
            reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
                       requester:(AMASearchAdsRequester *)requester
                        reporter:(AMASearchAdsReporter *)reporter;

- (void)trigger;

@end
