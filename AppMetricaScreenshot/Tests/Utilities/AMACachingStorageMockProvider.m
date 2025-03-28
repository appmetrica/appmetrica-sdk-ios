#import "AMACachingStorageMockProvider.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

@implementation AMACachingStorageMockProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mockedCachingStorage = [AMAKeyValueStorageMock new];
    }
    return self;
}

- (id<AMAKeyValueStoring>)cachingStorage
{
    return self.mockedCachingStorage;
}

@end
