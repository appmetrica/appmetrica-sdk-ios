
#import <Foundation/Foundation.h>
#import "AMAIDSyncRequest.h"

@class AMAIDSyncStartupConfiguration;
@class AMAIDSyncExecutionConditionProvider;
@class AMAIDSyncRequestsConverter;
@class AMAGenericRequestProcessor;
@class AMAIDSyncReporter;
@class AMAIDSyncPreconditionHandler;

@interface AMAIDSyncManager : NSObject

- (instancetype)initWithConditionProvider:(AMAIDSyncExecutionConditionProvider *)conditionProvider
                                converter:(AMAIDSyncRequestsConverter *)converter
                         requestProcessor:(AMAGenericRequestProcessor *)requestProcessor
                                 reporter:(AMAIDSyncReporter *)reporter
                      preconditionHandler:(AMAIDSyncPreconditionHandler *)preconditionHandler;

- (void)startIfNeeded;
- (void)shutdown;

- (void)startupUpdatedWithConfiguration:(AMAIDSyncStartupConfiguration *)configuration;

@end
