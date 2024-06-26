
#import <Foundation/Foundation.h>
#import "AMAAppMetricaImpl+TestUtilities.h"

@class AMAReporterTestHelper;
@protocol AMAHostStateProviding;

@interface AMAAppMetricaImplTestFactory : NSObject

+ (AMAAppMetricaImpl *)createNoQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                                 hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;
+ (AMAAppMetricaImpl *)createCurrentQueueImplWithReporterHelper:(AMAReporterTestHelper *)reporterTestHelper
                                              hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;

@end

@interface AMAAppMetricaImplStub : AMAAppMetricaImpl

@end
