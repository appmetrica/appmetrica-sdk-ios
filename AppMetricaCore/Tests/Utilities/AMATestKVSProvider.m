
#import "AMATestKVSProvider.h"
#import "AMAKeyValueStorage.h"
#import "AMAInMemoryKeyValueStorageDataProvider.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMAKeyValueStorageProvidersFactory.h"
#import "AMAGenericStringKeyValueStorageProvider.h"

@interface AMATestKVSProvider ()

@property (nonatomic, strong, readonly) id<AMAKeyValueStorageProviding> underlyingProvider;

@end

@implementation AMATestKVSProvider

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        id<AMAKeyValueStorageDataProviding> dataProvider = [[AMAInMemoryKeyValueStorageDataProvider alloc] init];
        _underlyingProvider = [[AMAGenericStringKeyValueStorageProvider alloc] initWithDataProvider:dataProvider];
    }
    return self;
}

- (id<AMAKeyValueStoring>)syncStorage
{
    return self.underlyingProvider.syncStorage;
}

- (id<AMAKeyValueStoring>)cachingStorage
{
    return self.underlyingProvider.cachingStorage;
}

- (id<AMAKeyValueStoring>)emptyNonPersistentStorage
{
    return [self.underlyingProvider emptyNonPersistentStorage];
}

- (void)inStorage:(void (^)(id<AMAKeyValueStoring>))block
{
    [self.underlyingProvider inStorage:block];
}

- (id<AMAKeyValueStoring>)nonPersistentStorageForKeys:(NSArray *)keys error:(NSError **)error
{
    return [self.underlyingProvider nonPersistentStorageForKeys:keys error:error];
}

- (id<AMAKeyValueStoring>)nonPersistentStorageForStorage:(id<AMAKeyValueStoring>)storage error:(NSError **)error
{
    return [self.underlyingProvider nonPersistentStorageForStorage:storage error:error];
}

- (BOOL)saveStorage:(id<AMAKeyValueStoring>)storage error:(NSError **)error
{
    return [self.underlyingProvider saveStorage:storage error:error];
}

- (id<AMAKeyValueStoring>)nonPersistentStorageForKeys:(NSArray *)keys db:(FMDatabase *)db error:(NSError **)error
{
    return [self nonPersistentStorageForKeys:keys error:error];
}

- (BOOL)saveStorage:(id<AMAKeyValueStoring>)storage db:(FMDatabase *)db error:(NSError **)error
{
    return [self saveStorage:storage error:error];
}

- (id<AMAKeyValueStoring>)storageForDB:(FMDatabase *)db
{
    return self.syncStorage;
}

- (void)addBackingKeys:(NSArray<NSString *> *)backingKeys
{
    // Do nothing?
}


@end
