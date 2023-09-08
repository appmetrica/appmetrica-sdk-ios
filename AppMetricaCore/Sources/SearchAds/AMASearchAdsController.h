
#import <Foundation/Foundation.h>

@protocol AMAExecuting;
@class AMASearchAdsRequester;
@class AMASearchAdsReporter;
@class AMAReporterStateStorage;

@interface AMASearchAdsController : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApiKey:(NSString *)apiKey
                      executor:(id<AMAExecuting>)executor
          reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage;
- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
            reporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
                       requester:(AMASearchAdsRequester *)requester
                        reporter:(AMASearchAdsReporter *)reporter;

- (void)trigger;

@end
