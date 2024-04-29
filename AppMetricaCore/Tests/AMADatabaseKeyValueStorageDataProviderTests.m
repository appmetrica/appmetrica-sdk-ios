
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAMockDatabase.h"
#import "AMADatabaseConstants.h"
#import "AMADatabaseKVSDataProvider.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

typedef void(^AMAWithProviderBlock)(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db);

SPEC_BEGIN(AMADatabaseKeyValueStorageDataProviderTests)

describe(@"AMADatabaseKeyValueStorageDataProvider", ^{

    NSString *const key = @"KEY";
    NSString *const value = @"VALUE";

    AMAMockDatabase *__block database = nil;

    beforeEach(^{
        database = [AMAMockDatabase simpleKVDatabase];
    });

    void (^withProvider)(AMAWithProviderBlock block) = ^(AMAWithProviderBlock block) {
        [database inDatabase:^(AMAFMDatabase *db) {
            AMADatabaseKVSDataProvider *provider =
                [[AMADatabaseKVSDataProvider alloc] initWithDatabase:db
                                                                       tableName:kAMAKeyValueTableName
                                                                  objectProvider:^id(AMAFMResultSet *rs, NSUInteger columdIdx) {
                                                                      return [rs stringForColumnIndex:(int)columdIdx];
                                                                  }];
            block(provider, db);
        }];
    };

    it(@"Should store value", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:value forKey:key error:nil];
            [[[provider objectForKey:key error:nil] should] equal:value];
        });
    });
    it(@"Should store nil", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:nil forKey:key error:nil];
            [[[provider objectForKey:key error:nil] should] beNil];
        });
    });
    it(@"Should overwrite with value", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:nil forKey:key error:nil];
            [provider saveObject:value forKey:key error:nil];
            [[[provider objectForKey:key error:nil] should] equal:value];
        });
    });
    it(@"Should overwrite with nil", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:@"SOME" forKey:key error:nil];
            [provider saveObject:nil forKey:key error:nil];
            [[[provider objectForKey:key error:nil] should] beNil];
        });
    });
    it(@"Should return nil if no value", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [[[provider objectForKey:key error:nil] should] beNil];
        });
    });
    it(@"Should return empty array if no keys", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [[[provider allKeysWithError:nil] should] beEmpty];
        });
    });
    it(@"Should return all keys", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:@"A" forKey:@"a" error:nil];
            [provider saveObject:@"B" forKey:@"b" error:nil];
            [provider saveObject:@"C" forKey:@"c" error:nil];
            [[[provider allKeysWithError:nil] should] containObjectsInArray:@[ @"a", @"b", @"c" ]];
        });
    });
    it(@"Should return values for keys", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObject:@"A" forKey:@"a" error:nil];
            [provider saveObject:@"B" forKey:@"b" error:nil];
            [provider saveObject:@"C" forKey:@"c" error:nil];
            [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
        });
    });
    it(@"Should store values for keys", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
            [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"A", @"c": @"C" }];
        });
    });
    it(@"Should allow removing when storing values for keys", ^{
        withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
            [provider saveObjectsDictionary:@{ @"a": @"A", @"b": @"B", @"c": @"C" } error:nil];
            [provider saveObjectsDictionary:@{ @"a": @"AA", @"c": [NSNull null], @"d": @"D" } error:nil];
            [[[provider objectsForKeys:@[ @"a", @"c", @"d" ] error:nil] should] equal:@{ @"a": @"AA", @"d": @"D" }];
        });
    });

    context(@"Existing data", ^{
        it(@"Should return existing value", ^{
            withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                [db executeUpdate:@"INSERT INTO kv (k, v) VALUES (?, ?)" values:@[ key, value ] error:nil];
                [[[provider objectForKey:key error:nil] should] equal:value];
            });
        });
        it(@"Should return existing nil", ^{
            withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                [db executeUpdate:@"INSERT INTO kv (k, v) VALUES (?, ?)" values:@[ key, [NSNull null] ] error:nil];
                [[[provider objectForKey:key error:nil] should] beNil];
            });
        });
    });

    context(@"Error handling", ^{
        NSError *const expectedError = [NSError errorWithDomain:@"DOMAIN" code:1 userInfo:nil];
        context(@"Query error", ^{
            void (^stubError)(AMAFMDatabase *db) = ^(AMAFMDatabase *db) {
                [db stub:@selector(executeQuery:values:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                    return nil;
                }];
                [db stub:@selector(executeUpdate:values:error:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[2] withValue:expectedError];
                    return nil;
                }];
            };

            context(@"Get", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider objectForKey:key error:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider objectForKey:key error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"Save", ^{
                it(@"Should return NO", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[theValue([provider saveObject:@"SOME" forKey:key error:nil]) should] beNo];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider saveObject:@"SOME" forKey:key error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"Remove", ^{
                it(@"Should return NO", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[theValue([provider removeKey:key error:nil]) should] beNo];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider removeKey:key error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"All keys", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider allKeysWithError:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider allKeysWithError:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"Get many", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider objectsForKeys:@[@"a"] error:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider objectsForKeys:@[@"a"] error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"Save many", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[theValue([provider saveObjectsDictionary:@{ @"a": @"A" } error:nil]) should] beNo];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider saveObjectsDictionary:@{ @"a": @"A" } error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
        });

        context(@"Next error", ^{
            AMAFMResultSet *__block resultSet = nil;
            void (^stubError)(AMAFMDatabase *db) = ^(AMAFMDatabase *db) {
                resultSet = [AMAFMResultSet nullMock];
                [resultSet stub:@selector(nextWithError:) withBlock:^id(NSArray *params) {
                    [AMATestUtilities fillObjectPointerParameter:params[0] withValue:expectedError];
                    return theValue(NO);
                }];
                [db stub:@selector(executeQuery:values:error:) andReturn:resultSet];
            };

            context(@"Get", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider objectForKey:key error:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider objectForKey:key error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"All keys", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider allKeysWithError:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider allKeysWithError:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
            context(@"Get many", ^{
                it(@"Should return nil", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        [[[provider objectsForKeys:@[@"a"] error:nil] should] beNil];
                    });
                });
                it(@"Should fill error", ^{
                    withProvider(^(AMADatabaseKVSDataProvider *provider, AMAFMDatabase *db) {
                        stubError(db);
                        NSError *error = nil;
                        [provider objectsForKeys:@[@"a"] error:&error];
                        [[error should] equal:expectedError];
                    });
                });
            });
        });
    });
    
    it(@"Should conform to AMAKeyValueStorageDataProviding", ^{
        AMADatabaseKVSDataProvider *provider =
            [[AMADatabaseKVSDataProvider alloc] initWithDatabase:nil
                                                       tableName:kAMAKeyValueTableName
                                                  objectProvider:nil];
        [[provider should] conformToProtocol:@protocol(AMAKeyValueStorageDataProviding)];
    });
});

SPEC_END

