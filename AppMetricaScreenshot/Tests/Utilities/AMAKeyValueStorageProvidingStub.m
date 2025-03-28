#import "AMAKeyValueStorageProvidingStub.h"

@implementation AMAKeyValueStorageProvidingStub

- (id<AMAKeyValueStoring>)syncStorage
{
    return nil;
}

- (id<AMAKeyValueStoring>)cachingStorage
{
    return nil;
}

- (id<AMAKeyValueStoring>)emptyNonPersistentStorage
{
    return nil;
}

- (void)inStorage:(void (^)(id<AMAKeyValueStoring>))block
{
}

- (id<AMAKeyValueStoring>)nonPersistentStorageForKeys:(NSArray *)keys
                                                error:(NSError *__autoreleasing *)error
{
    return nil;
}

- (id<AMAKeyValueStoring>)nonPersistentStorageForStorage:(id<AMAKeyValueStoring>)storage
                                                   error:(NSError *__autoreleasing *)error
{
    return nil;
}

- (BOOL)saveStorage:(id<AMAKeyValueStoring>)storage
              error:(NSError *__autoreleasing *)error
{
    return NO;
}

@end
