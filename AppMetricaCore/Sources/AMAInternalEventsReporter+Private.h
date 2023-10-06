#import "AMAInternalEventsReporter.h"

#import <AppMetricaHostState/AppMetricaHostState.h>

@protocol AMAExecuting;
@protocol AMAReporterProviding;
@protocol AMAHostStateProviding;

@interface AMAInternalEventsReporter () <AMAHostStateProviderDelegate>

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                reporterProvider:(id<AMAReporterProviding>)reporterProvider;
- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                reporterProvider:(id<AMAReporterProviding>)reporterProvider
               hostStateProvider:(id<AMAHostStateProviding>)hostStateProvider;

@end
