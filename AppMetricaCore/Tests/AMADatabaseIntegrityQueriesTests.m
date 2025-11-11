
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADatabaseIntegrityQueries.h"
#import <sqlite3.h>
#import <AppMetricaFMDB/AppMetricaFMDB.h>
#import "AMASQLiteIntegrityIssue.h"

SPEC_BEGIN(AMADatabaseIntegrityQueriesTests)

describe(@"AMADatabaseIntegrityQueries", ^{

    NSError *__block error = nil;
    NSString *__block databasePath = nil;
    AMAFMDatabaseQueue *__block database = nil;

    beforeEach(^{
        error = nil;

        NSString *databaseResourcePath =
            [AMAModuleBundleProvider.moduleBundle pathForResource:@"test_integrity_source_database"
                                                             ofType:@"sqlite"];

        NSString *databaseName = [[NSUUID UUID] UUIDString];
        databasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:databaseName];
        [[NSFileManager defaultManager] copyItemAtPath:databaseResourcePath toPath:databasePath error:nil];

        database = [[AMAFMDatabaseQueue alloc] initWithPath:databasePath
                                                   flags:(SQLITE_OPEN_READWRITE |
                                                          SQLITE_OPEN_FILEPROTECTION_NONE)];
    });

    afterEach(^{
        [database close];
        [[NSFileManager defaultManager] removeItemAtPath:databasePath error:nil];
    });

    __auto_type dbError = ^NSError *(NSInteger code, NSString *description) {
        return [NSError errorWithDomain:kAMAFMDBErrorDomain
                                   code:code
                               userInfo:@{ NSLocalizedDescriptionKey: description }];
    };
    __auto_type writeToDB = ^(unsigned long long offset, void *data, NSUInteger size) {
        [database close];
        NSFileHandle *dbFile = [NSFileHandle fileHandleForUpdatingAtPath:databasePath];
        [dbFile seekToFileOffset:offset];
        [dbFile writeData:[NSData dataWithBytes:data length:size]];
        [dbFile closeFile];
        database = [[AMAFMDatabaseQueue alloc] initWithPath:databasePath
                                                   flags:(SQLITE_OPEN_READWRITE |
                                                          SQLITE_OPEN_FILEPROTECTION_NONE)];
    };

    context(@"Integrity check", ^{
        NSArray *__block issues = nil;

        context(@"No issues", ^{
            beforeEach(^{
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should be empty", ^{
                [[issues should] beEmpty];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
        context(@"Wrong header", ^{
            beforeEach(^{
                char value[] = "some of 16 bytes"; // Instead of "SQLite format 3\0"
                writeToDB(0, &value, 16);
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should be nil", ^{
                [[issues should] beNil];
            });
            it(@"Should fill error", ^{
                [[theValue(error.code) should] equal:theValue(SQLITE_NOTADB)];
            });
        });
        context(@"Smaller page size", ^{
            beforeEach(^{
                uint16_t value = CFSwapInt16HostToBig(2048); // expected 4096
                writeToDB(16, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should be nil", ^{
                [[issues should] beNil];
            });
            it(@"Should fill error", ^{
                [[theValue(error.code) should] equal:theValue(SQLITE_CORRUPT)];
            });
        });
        context(@"Bigger page size", ^{
            beforeEach(^{
                uint16_t value = CFSwapInt16HostToBig(8192); // expected 4096
                writeToDB(16, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should be nil", ^{
                [[issues should] beNil];
            });
            it(@"Should fill error", ^{
                [[error should] equal:dbError(SQLITE_CORRUPT, @"database disk image is malformed")];
            });
        });
        context(@"Malform schema", ^{
            beforeEach(^{
                char value[] = "_____"; // Overwrite CREATE from "CREATE TABLE..."
                writeToDB(0xF89, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should be nil", ^{
                [[issues should] beNil];
            });
            it(@"Should fill error", ^{
                [[error should] equal:dbError(SQLITE_CORRUPT, @"malformed database schema (test)")];
            });
        });
        context(@"Overwrite value to break uniqueness", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x1FD6, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should have valid issues", ^{
                [[issues should] equal:@[@"row 6 missing from index sqlite_autoindex_test_1"]];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
        context(@"Overwrite value to break rows order", ^{
            beforeEach(^{
                uint8_t value = 5; // Was 6 from (6, 7, 'e') value
                writeToDB(0x1FD1, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should have valid issues", ^{
                [[issues should] contain:@"row 6 missing from index sqlite_autoindex_test_1"];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
        context(@"Overwrite value to break uniq index", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x2FE1, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should have valid issues", ^{
                [[issues should] equal:@[
                    @"non-unique entry in index sqlite_autoindex_test_1",
                    @"row 6 missing from index sqlite_autoindex_test_1"
                ]];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
        context(@"Overwrite value to break row id index", ^{
            beforeEach(^{
                uint8_t value = 5; // Was 6 from (6, 7, 'e') value
                writeToDB(0x2FE2, &value, sizeof(value));
                issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
            });
            it(@"Should have valid issues", ^{
                [[issues should] equal:@[
                    @"row 6 missing from index sqlite_autoindex_test_1"
                ]];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
    });

    context(@"Fix index", ^{
        BOOL __block result = NO;

        context(@"Not broken", ^{
            beforeEach(^{
                result = [AMADatabaseIntegrityQueries fixIntegrityForDBQueue:database error:&error];
            });
            it(@"Should return YES", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
        });
        context(@"Broken value", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x1FD6, &value, sizeof(value));
                result = [AMADatabaseIntegrityQueries fixIntegrityForDBQueue:database error:&error];
            });
            it(@"Should return NO", ^{
                [[theValue(result) should] beNo];
            });
            it(@"Should fill error", ^{
                [[error should] equal:dbError(SQLITE_CONSTRAINT, @"UNIQUE constraint failed: test.b")];
            });
        });
        context(@"Broken index", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x2FE1, &value, sizeof(value));
                result = [AMADatabaseIntegrityQueries fixIntegrityForDBQueue:database error:&error];
            });
            it(@"Should return NO", ^{
                [[theValue(result) should] beYes];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
            context(@"Additional integrity check", ^{
                NSArray *__block issues = nil;

                beforeEach(^{
                    issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
                });
                it(@"Should be empty", ^{
                    [[issues should] beEmpty];
                });
                it(@"Should not fill error", ^{
                    [[error should] beNil];
                });
            });
        });
    });

    context(@"Backup database", ^{
        NSArray *const expectedValues = @[
            @{ @"a": @1, @"b": @2, @"c": @"a" },
            @{ @"a": @2, @"b": @3, @"c": @"a" },
            @{ @"a": @3, @"b": @4, @"c": @"b" },
            @{ @"a": @4, @"b": @5, @"c": @"c" },
            @{ @"a": @5, @"b": @6, @"c": @"d" },
            @{ @"a": @6, @"b": @7, @"c": @"e" },
        ];

        BOOL __block result = NO;
        NSArray *__block issues = nil;
        NSString *__block backupPath = nil;
        AMAFMDatabaseQueue *__block backupDatabase = nil;

        beforeEach(^{
            backupPath = [databasePath stringByAppendingPathExtension:@"bak"];
            backupDatabase = [[AMAFMDatabaseQueue alloc] initWithPath:backupPath
                                                             flags:(SQLITE_OPEN_READWRITE |
                                                                    SQLITE_OPEN_CREATE |
                                                                    SQLITE_OPEN_FILEPROTECTION_NONE)];
        });
        afterEach(^{
            [backupDatabase close];
            [[NSFileManager defaultManager] removeItemAtPath:backupPath error:nil];
        });

        __auto_type extractValues = ^NSArray<NSDictionary *> *{
            NSMutableArray *result = [NSMutableArray array];
            [backupDatabase inDatabase:^(AMAFMDatabase * _Nonnull db) {
                AMAFMResultSet *rs = [db executeQuery:@"SELECT * FROM test"];
                while ([rs next]) {
                    [result addObject:rs.resultDictionary];
                }
                [rs close];
            }];
            return [result copy];
        };

        context(@"Not broken", ^{
            beforeEach(^{
                result = [AMADatabaseIntegrityQueries backupDBQueue:database backupDB:backupDatabase error:&error];
            });
            it(@"Should have all values", ^{
                [[extractValues() should] equal:expectedValues];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
            context(@"Additional integrity check", ^{
                beforeEach(^{
                    issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
                });
                it(@"Should be empty", ^{
                    [[issues should] beEmpty];
                });
                it(@"Should not fill error", ^{
                    [[error should] beNil];
                });
            });
        });
        context(@"Broken value", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x1FD6, &value, sizeof(value));
                result = [AMADatabaseIntegrityQueries backupDBQueue:database backupDB:backupDatabase error:&error];
            });
            it(@"Should have all values", ^{
                NSArray *brokenValues = @[
                    @{ @"a": @1, @"b": @2, @"c": @"a" },
                    @{ @"a": @2, @"b": @3, @"c": @"a" },
                    @{ @"a": @3, @"b": @4, @"c": @"b" },
                    @{ @"a": @4, @"b": @5, @"c": @"c" },
                    @{ @"a": @5, @"b": @6, @"c": @"d" },
                    @{ @"a": @6, @"b": @6, @"c": @"e" }, // b is 6 instead of 7
                ];
                [[extractValues() should] equal:brokenValues];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
            context(@"Additional integrity check", ^{
                beforeEach(^{
                    issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
                });
                it(@"Should remain index issues", ^{
                    [[issues should] equal:@[
                        @"row 6 missing from index sqlite_autoindex_test_1"
                    ]];
                });
                it(@"Should not fill error", ^{
                    [[error should] beNil];
                });
            });
        });
        context(@"Broken index", ^{
            beforeEach(^{
                uint8_t value = 6; // Was 7 from (6, 7, 'e') value
                writeToDB(0x2FE1, &value, sizeof(value));
                result = [AMADatabaseIntegrityQueries backupDBQueue:database backupDB:backupDatabase error:&error];
            });
            it(@"Should have all values", ^{
                [[extractValues() should] equal:expectedValues];
            });
            it(@"Should not fill error", ^{
                [[error should] beNil];
            });
            context(@"Additional integrity check", ^{
                beforeEach(^{
                    issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
                });
                it(@"Should remain index issues", ^{
                    [[issues should] equal:@[
                        @"non-unique entry in index sqlite_autoindex_test_1",
                        @"row 6 missing from index sqlite_autoindex_test_1"
                    ]];
                });
                it(@"Should not fill error", ^{
                    [[error should] beNil];
                });
            });
        });
        context(@"Malformed db image", ^{
            beforeEach(^{
                uint16_t value = CFSwapInt16HostToBig(8192); // expected 4096
                writeToDB(16, &value, sizeof(value));
                result = [AMADatabaseIntegrityQueries backupDBQueue:database backupDB:backupDatabase error:&error];
            });
            it(@"Should have all values", ^{
                [[extractValues() should] beEmpty];
            });
            it(@"Should fill error", ^{
                [[error should] equal:dbError(SQLITE_CORRUPT, @"database disk image is malformed")];
            });
            context(@"Additional integrity check", ^{
                beforeEach(^{
                    issues = [AMADatabaseIntegrityQueries integrityIssuesForDBQueue:database error:&error];
                });
                it(@"Should be nil", ^{
                    [[issues should] beNil];
                });
                it(@"Should fill same error", ^{
                    [[error should] equal:dbError(SQLITE_CORRUPT, @"database disk image is malformed")];
                });
            });
        });
    });

});

SPEC_END
