
#import "AMAIDSyncLastExecutionStateProvider.h"
#import "AMAIDSyncRequest.h"
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

static NSString *const kAMAIDSyncLastExecutionDateStorageKey = @"id.sync.last_execution_date";
static NSString *const kAMAIDSyncLastExecutionCodeStorageKey = @"id.sync.last_execution_code";

@interface AMAIDSyncLastExecutionStateProvider ()

@property (nonatomic, strong, readonly) AMAUserDefaultsStorage *storage;

@end

@implementation AMAIDSyncLastExecutionStateProvider

- (instancetype)init
{
    return [self initWithStorage:[[AMAUserDefaultsStorage alloc] init]];
}

- (instancetype)initWithStorage:(AMAUserDefaultsStorage *)storage
{
    self = [super init];
    if (self) {
        _storage = storage;
    }
    return self;
}

- (NSDate *)lastExecutionDateForRequest:(AMAIDSyncRequest *)request
{
    return [self.storage objectForKey:[self lastExecutionDateStorageKey:request]];
}

- (BOOL)lastExecutionStatusForRequest:(AMAIDSyncRequest *)request
{
    NSNumber *statusCode = [self.storage objectForKey:[self lastExecutionCodeStorageKey:request]];
    
    if (statusCode == nil) {
        return YES;
    }
    
    return [request.validResponseCodes containsObject:statusCode];
}

- (void)requestExecuted:(AMAIDSyncRequest *)request
             statusCode:(NSNumber *)statusCode
{
    [self.storage setObject:[NSDate date] forKey:[self lastExecutionDateStorageKey:request]];
    [self.storage setObject:statusCode forKey:[self lastExecutionCodeStorageKey:request]];
}

#pragma mark - Private -

- (NSString *)lastExecutionDateStorageKey:(AMAIDSyncRequest *)request
{
    return [NSString stringWithFormat:@"%@.%@", kAMAIDSyncLastExecutionDateStorageKey, request.type];
}

- (NSString *)lastExecutionCodeStorageKey:(AMAIDSyncRequest *)request
{
    return [NSString stringWithFormat:@"%@.%@", kAMAIDSyncLastExecutionCodeStorageKey, request.type];
}

@end
