
#import <Foundation/Foundation.h>

@class AMAIDSyncRequest;
@class AMAUserDefaultsStorage;

@interface AMAIDSyncLastExecutionStateProvider : NSObject

- (NSDate *)lastExecutionDateForRequest:(AMAIDSyncRequest *)request;
- (BOOL)lastExecutionStatusForRequest:(AMAIDSyncRequest *)request;

- (void)requestExecuted:(AMAIDSyncRequest *)request
             statusCode:(NSNumber *)statusCode;

- (instancetype)initWithStorage:(AMAUserDefaultsStorage *)storage;

@end
