
#import "AMAIDSyncLastExecutionStateProviderMock.h"

@implementation AMAIDSyncLastExecutionStateProviderMock

- (NSDate *)lastExecutionDateForRequest:(AMAIDSyncRequest *)request
{
    return self.stubLastExecutionDate;
}

- (BOOL)lastExecutionStatusForRequest:(AMAIDSyncRequest *)request
{
    return self.stubLastExecutionStatus;
}

- (void)requestExecuted:(AMAIDSyncRequest *)request statusCode:(NSNumber *)statusCode
{
    self.capturedRequest = request;
    self.capturedStatusCode = statusCode;
}

@end
