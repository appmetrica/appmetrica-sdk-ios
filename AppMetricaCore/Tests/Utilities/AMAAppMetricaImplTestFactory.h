
#import <Foundation/Foundation.h>
#import "AMAAppMetricaImpl+TestUtilities.h"

@class AMAReporterTestHelper;
@class AMAAdProviderProxy;
@class AMAModulesController;
@class AMAModuleEntryPointDiscovererMock;
@protocol AMAHostStateProviding;

NS_ASSUME_NONNULL_BEGIN

@interface AMAAppMetricaImplTestFactory : NSObject

+ (AMAAppMetricaImpl *)createNoQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                              hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;

@end

@interface AMAAppMetricaImplStub : AMAAppMetricaImpl

@property (nonatomic, strong) AMAAdProviderProxy *adProviderProxy;
@property (nonatomic, strong) AMAModulesController *modulesController;
@property (nonatomic, strong, readonly) AMAModuleEntryPointDiscovererMock *moduleEntryPointDiscoverer;

- (instancetype)initWithHostStateProvider:(nullable id<AMAHostStateProviding>)hostStateProvider
                                 executor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
                       reporterTestHelper:(AMAReporterTestHelper *)reporterTestHelper;

@end

NS_ASSUME_NONNULL_END
