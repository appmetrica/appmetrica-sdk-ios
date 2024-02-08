
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMAIncrementableValueStorageMock

- (instancetype)init
{
    return [super initWithKey:@"key" defaultValue:0];
}

- (NSNumber *)valueWithStorage:(id<AMAKeyValueStoring>)storage
{
    return self.currentMockValue;
}

- (NSNumber *)nextInStorage:(id<AMAKeyValueStoring>)storage
                   rollback:(AMARollbackHolder *)rollbackHolder
                      error:(NSError **)error
{
    self.currentMockValue = [NSNumber numberWithLongLong:[self.currentMockValue longLongValue] + 1];
    return self.currentMockValue;
}

@end
