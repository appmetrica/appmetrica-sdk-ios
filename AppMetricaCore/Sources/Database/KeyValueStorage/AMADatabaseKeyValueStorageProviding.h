
#import <Foundation/Foundation.h>
#import "AMACore.h"

@protocol AMAKeyValueStoring;
@protocol AMADatabaseProtocol;
@protocol AMAKeyValueStorageProviding;
@class FMDatabase;

@protocol AMADatabaseKeyValueStorageProviding <AMAKeyValueStorageProviding>

- (void)setDatabase:(id<AMADatabaseProtocol>)database;

- (id<AMAKeyValueStoring>)storageForDB:(FMDatabase *)db;

- (id<AMAKeyValueStoring>)nonPersistentStorageForKeys:(NSArray *)keys db:(FMDatabase *)db error:(NSError **)error;
- (BOOL)saveStorage:(id<AMAKeyValueStoring>)storage db:(FMDatabase *)db error:(NSError **)error;

- (void)addBackingKeys:(NSArray<NSString *> *)backingKeys;

@end
