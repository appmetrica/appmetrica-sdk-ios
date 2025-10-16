
#import <Foundation/Foundation.h>
#import "AMAIDSyncLastExecutionStateProvider.h"

@class AMAIDSyncRequest;

@interface AMAIDSyncLastExecutionStateProviderMock : AMAIDSyncLastExecutionStateProvider

@property (nonatomic, strong) NSDate *stubLastExecutionDate;
@property (nonatomic, assign) BOOL stubLastExecutionStatus;
@property (nonatomic, strong) AMAIDSyncRequest *capturedRequest;
@property (nonatomic, strong) NSNumber *capturedStatusCode;

@end
