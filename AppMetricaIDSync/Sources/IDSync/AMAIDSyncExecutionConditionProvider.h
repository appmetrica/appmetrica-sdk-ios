
#import <Foundation/Foundation.h>

@protocol AMAExecutionCondition;
@class AMAIDSyncRequest;
@class AMAIDSyncLastExecutionStateProvider;

@interface AMAIDSyncExecutionConditionProvider : NSObject

- (id<AMAExecutionCondition>)executionConditionWithRequest:(AMAIDSyncRequest *)request;
- (void)execute:(AMAIDSyncRequest *)request statusCode:(NSNumber *)statusCode;

- (instancetype)initWithLastExecutionStateProvider:(AMAIDSyncLastExecutionStateProvider *)lastExecutionProvider;

@end
