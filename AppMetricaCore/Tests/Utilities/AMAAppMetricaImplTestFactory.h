
#import <Foundation/Foundation.h>
#import "AMAAppMetricaImpl+TestUtilities.h"

@class AMAReporterTestHelper;
@protocol AMAHostStateProviding;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaImplTestFactory : NSObject

+ (AMAAppMetricaImpl *)createNoQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                                 hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                              hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;

@end

@interface AMAAppMetricaImplStub : AMAAppMetricaImpl

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
                       reporterTestHelper:(AMAReporterTestHelper *)reporterTestHelper;

@end

NS_ASSUME_NONNULL_END
