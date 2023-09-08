
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
@import FMDB;
#import "AMADatabaseKeyValueStorageProvider.h"
#import "AMADatabaseObjectProvider.h"
#import "AMAMockDatabase.h"
#import "AMAStringDatabaseKeyValueStorageConverter.h"
#import "AMAInMemoryKeyValueStorageDataProvider.h"

SPEC_BEGIN(AMADatabaseKeyValueStorageProviderTests)

describe(@"AMADatabaseKeyValueStorageProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    AMAMockDatabase *__block database = nil;
    AMAStringDatabaseKeyValueStorageConverter *__block converter = nil;
    AMADatabaseKeyValueStorageProvider *__block provider = nil;

    beforeEach(^{
        database = [AMAMockDatabase simpleKVDatabase];
        converter = [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
        provider = [[AMADatabaseKeyValueStorageProvider alloc] initWithTableName:@"kv"
                                                                       converter:converter
                                                                  objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                          backingKVSDataProvider:nil];
        provider.database = database;
    });

    void (^addValues)(void) = ^{
        [database inDatabase:^(FMDatabase *db) {
            [db executeUpdate:@"INSERT INTO kv (k,v) VALUES (?, ?)" values:@[ key, value ] error:nil];
        }];
    };

    NSString *(^existingValue)(void) = ^{
        NSString *__block result = nil;
        [database inDatabase:^(FMDatabase *db) {
            FMResultSet *rs = [db executeQuery:@"SELECT v FROM kv WHERE k = ? LIMIT 1" values:@[ key ] error:nil];
            if ([rs next]) {
                result = [rs stringForColumnIndex:0];
            }
            [rs close];
        }];
        return result;
    };

    context(@"Sync storage", ^{
        id<AMAKeyValueStoring> __block storage = nil;
        beforeEach(^{
            storage = provider.syncStorage;
        });
        it(@"Should return nil", ^{
            [[[storage stringForKey:key error:nil] should] beNil];
        });
        it(@"Should return value if exists", ^{
            addValues();
            [[[storage stringForKey:key error:nil] should] equal:value];
        });
        it(@"Should write value", ^{
            [storage saveString:value forKey:key error:nil];
            [[existingValue() should] equal:value];
        });
    });

    context(@"Caching storage", ^{
        NSObject<AMAKeyValueStoring> *__block storage = nil;
        beforeEach(^{
            storage = (NSObject<AMAKeyValueStoring> *)provider.cachingStorage;
        });
        it(@"Should return nil", ^{
            [[[storage stringForKey:key error:nil] should] beNil];
        });
        it(@"Should return value if exists", ^{
            addValues();
            [[[storage stringForKey:key error:nil] should] equal:value];
        });
        it(@"Should not write value first time", ^{
            [[database shouldNot] receive:@selector(inDatabase:)];
            [storage saveString:value forKey:key error:nil];
        });
        it(@"Should flush on open database", ^{
            [storage saveString:value forKey:key error:nil];
            [[storage should] receive:@selector(flush)];
            [database inDatabase:^(FMDatabase *db) {
                // Do nothing
            }];
        });
    });

    context(@"In storage", ^{
        it(@"Should return value", ^{
            addValues();
            NSString *__block result = nil;
            [provider inStorage:^(id<AMAKeyValueStoring> storage) {
                result = [storage stringForKey:key error:nil];
            }];
            [[result should] equal:value];
        });
    });

    context(@"Storage for DB", ^{
        it(@"Should return value", ^{
            addValues();
            [database inDatabase:^(FMDatabase *db) {
                [[[[provider storageForDB:db] stringForKey:key error:nil] should] equal:value];
            }];
        });
    });

    context(@"Non-persistent storage", ^{
        it(@"Should return add values via empty storage", ^{
            id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
            [storage saveString:value forKey:key error:nil];
            [provider saveStorage:storage error:nil];
            [[[provider.syncStorage stringForKey:key error:nil] should] equal:value];
        });
        it(@"Should return remove values via empty storage", ^{
            addValues();
            id<AMAKeyValueStoring> storage = [provider emptyNonPersistentStorage];
            [storage saveString:nil forKey:key error:nil];
            [provider saveStorage:storage error:nil];
            [[[provider.syncStorage stringForKey:key error:nil] should] beNil];
        });
        it(@"Should return storage for keys", ^{
            addValues();
            id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
            [[[storage stringForKey:key error:nil] should] equal:value];
        });
        it(@"Should return storage copy for storage", ^{
            addValues();
            id<AMAKeyValueStoring> storage = [provider nonPersistentStorageForKeys:@[ key ] error:nil];
            id<AMAKeyValueStoring> storageCopy = [provider nonPersistentStorageForStorage:storage error:nil];
            [[[storageCopy stringForKey:key error:nil] should] equal:value];
        });
        context(@"Error", ^{
            it(@"Should return NO for wrong type storage", ^{
                [AMATestUtilities stubAssertions];
                id<AMAKeyValueStoring> storage = [KWMock nullMockForProtocol:@protocol(AMAKeyValueStoring)];
                [[theValue([provider saveStorage:storage error:nil]) should] beNo];
            });
            it(@"Should return NO for wrong type converter", ^{
                [AMATestUtilities stubAssertions];
                NSObject<AMAKeyValueStoring> *storage =
                    (NSObject<AMAKeyValueStoring> *)[provider emptyNonPersistentStorage];
                [storage stub:@selector(converter) andReturn:[KWMock nullMockForProtocol:@protocol(AMAKeyValueStorageConverting)]];
                [[theValue([provider saveStorage:storage error:nil]) should] beNo];
            });
        });
    });
    
    context(@"Backing storage", ^{
        
        NSString *const backedKey = @"backedKey";
        NSString *const backedValue = @"backedValue";
        
        AMAInMemoryKeyValueStorageDataProvider *__block backingDataProvider = nil;
        NSMutableDictionary *__block backingStorage;
        
        beforeEach(^{
            backingStorage = [NSMutableDictionary dictionary];
            backingDataProvider = [[AMAInMemoryKeyValueStorageDataProvider alloc] initWithDictionary:backingStorage];
            provider = [[AMADatabaseKeyValueStorageProvider alloc] initWithTableName:@"kv"
                                                                           converter:converter
                                                                      objectProvider:[AMADatabaseObjectProvider blockForStrings]
                                                              backingKVSDataProvider:backingDataProvider];
        });
        
        it(@"Should return value from original DB", ^{
            addValues();
            [database inDatabase:^(FMDatabase *db) {
                [[[[provider storageForDB:db] stringForKey:key error:nil] should] equal:value];
            }];
        });
        
        it(@"Should not return value from backed DB if the keys were not added", ^{
            backingStorage[backedKey] = backingStorage[backedValue];
            
            [database inDatabase:^(FMDatabase *db) {
                [[[[provider storageForDB:db] stringForKey:backedKey error:nil] should] beNil];
            }];
        });
        
        it(@"Should return value from backed DB if the keys were added", ^{
            backingStorage[backedKey] = backedValue;
            [provider addBackingKeys:@[ backedKey ]];
            
            [database inDatabase:^(FMDatabase *db) {
                [[[[provider storageForDB:db] stringForKey:backedKey error:nil] should] equal:backedValue];
            }];
        });
    });
});

SPEC_END

