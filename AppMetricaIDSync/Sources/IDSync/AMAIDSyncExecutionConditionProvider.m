
#import "AMAIDSyncCore.h"
#import "AMAIDSyncExecutionConditionProvider.h"
#import "AMAIDSyncRequest.h"
#import "AMAIDSyncRequestsConverter.h"
#import "AMAIDSyncLastExecutionStateProvider.h"

@interface AMAIDSyncExecutionConditionProvider ()

@property (nonatomic, strong, readonly) AMAIDSyncLastExecutionStateProvider *lastExecutionProvider;

@end

@implementation AMAIDSyncExecutionConditionProvider

- (instancetype)init
{
    return [self initWithLastExecutionStateProvider:[[AMAIDSyncLastExecutionStateProvider alloc] init]];
}

- (instancetype)initWithLastExecutionStateProvider:(AMAIDSyncLastExecutionStateProvider *)lastExecutionProvider
{
    self = [super init];
    if (self) {
        _lastExecutionProvider = lastExecutionProvider;
    }
    return self;
}

- (id<AMAExecutionCondition>)executionConditionWithRequest:(AMAIDSyncRequest *)request
{
    BOOL validResponse = [self.lastExecutionProvider lastExecutionStatusForRequest:request];
    NSDate *lastExecuted = [self.lastExecutionProvider lastExecutionDateForRequest:request];
    
    NSTimeInterval defaultInterval = validResponse
        ? kAMAIDSyncDefaultValidResendInterval
        : kAMAIDSyncDefaultInvalidResendInterval;

    NSNumber *requestedInterval = validResponse
        ? request.resendIntervalForValidResponse
        : request.resendIntervalForNotValidResponse;

    NSTimeInterval interval = [AMATimeUtilities intervalWithNumber:requestedInterval
                                                   defaultInterval:defaultInterval];

    return [[AMAIntervalExecutionCondition alloc] initWithLastExecuted:lastExecuted
                                                              interval:interval
                                                   underlyingCondition:nil];
}

- (void)execute:(AMAIDSyncRequest *)request statusCode:(NSNumber *)statusCode
{
    [self.lastExecutionProvider requestExecuted:request statusCode:statusCode];
}

@end
