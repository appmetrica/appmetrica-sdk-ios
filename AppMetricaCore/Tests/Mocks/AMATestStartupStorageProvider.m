
#import "AMATestStartupStorageProvider.h"

@implementation AMATestStartupStorageProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        _savedStorages = [NSMutableArray array];
    }
    return self;
}

- (id<AMAKeyValueStoring>)startupStorageForKeys:(NSArray<NSString *> *)keys
{
    return self.storage;
}

- (void)saveStorage:(id<AMAKeyValueStoring>)storage
{
    [self.savedStorages addObject:storage];
}

@end

@implementation AMATestCachingStorageProvider

- (id<AMAKeyValueStoring>)cachingStorage
{
    return nil;
}

@end
