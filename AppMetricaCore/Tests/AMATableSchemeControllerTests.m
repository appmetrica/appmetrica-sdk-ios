
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMATableSchemeController.h"
#import "AMADatabaseConstants.h"
#import "AMATableDescriptionProvider.h"
#import <AppMetricaFMDB/AppMetricaFMDB.h>

SPEC_BEGIN(AMATableSchemeControllerTests)

describe(@"AMATableSchemeController", ^{

    NSString *const expectedSQL =
        @"CREATE TABLE t_1 (f_1 INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, f_2 STRING DEFAULT V, f_3 BLOB)";

    AMAFMDatabaseQueue *__block databaseQueue = nil;
    AMATableSchemeController *__block controller = nil;

    beforeEach(^{
        databaseQueue = [[AMAFMDatabaseQueue alloc] init];
        NSDictionary *schemes = @{
            @"t_1": @[
                @{ kAMASQLName: @"f_1", kAMASQLType: @"INTEGER", kAMASQLIsNotNull: @YES, kAMASQLIsPrimaryKey: @YES, kAMASQLIsAutoincrement: @YES },
                @{ kAMASQLName: @"f_2", kAMASQLType: @"STRING", kAMASQLDefaultValue: @"V"},
                @{ kAMASQLName: @"f_3", kAMASQLType: @"BLOB"},
            ],
        };
        controller = [[AMATableSchemeController alloc] initWithTableSchemes:schemes];
    });

    NSString *(^schemaSQL)(void) = ^{
        NSString *__block result = nil;
        [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
            AMAFMResultSet *rs = [db getSchema];
            [[theValue([rs next]) should] beYes];
            result = [rs stringForColumn:@"sql"];
            [rs close];
        }];
        return result;
    };

    it(@"Should create scheme", ^{
        [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
            [controller createSchemaInDB:db];
        }];
        [[schemaSQL() should] equal:expectedSQL];
    });

    context(@"Consistency enforcing", ^{
        context(@"Consistent", ^{
            beforeEach(^{
                [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                    [db executeUpdate:expectedSQL];
                }];
            });
            it(@"Should not call on-inconsistency block", ^{
                BOOL __block called = NO;
                [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                    [controller enforceDatabaseConsistencyInDB:db onInconsistency:^(dispatch_block_t fix) {
                        called = YES;
                    }];
                }];
                [[theValue(called) should] beNo];
            });
        });
        context(@"Inconsistent", ^{
            context(@"Different field type", ^{
                NSString *differentSchemeSQL =
                    @"CREATE TABLE t_1 (f_1 INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, f_2 DOUBLE DEFAULT 0, f_3 BLOB)";
                beforeEach(^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [db executeUpdate:differentSchemeSQL];
                    }];
                });
                it(@"Should call on-inconsistency block", ^{
                    BOOL __block called = NO;
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:^(dispatch_block_t fix) {
                            called = YES;
                        }];
                    }];
                    [[theValue(called) should] beYes];
                });
                it(@"Should not change scheme if fix is not called", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:^(dispatch_block_t fix) {
                        }];
                    }];
                    [[schemaSQL() should] equal:differentSchemeSQL];
                });
                it(@"Should fix scheme if fix is called", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:^(dispatch_block_t fix) {
                            fix();
                        }];
                    }];
                    [[schemaSQL() should] equal:expectedSQL];
                });
                it(@"Should fix scheme if block is not passed", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:nil];
                    }];
                    [[schemaSQL() should] equal:expectedSQL];
                });
            });
            context(@"Different field name", ^{
                NSString *differentSchemeSQL =
                    @"CREATE TABLE t_1 (f_1 INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, f_other STRING DEFAULT V, f_3 BLOB)";
                beforeEach(^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [db executeUpdate:differentSchemeSQL];
                    }];
                });
                it(@"Should fix scheme", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:nil];
                    }];
                    [[schemaSQL() should] equal:expectedSQL];
                });
            });
            context(@"Field absent", ^{
                NSString *differentSchemeSQL =
                    @"CREATE TABLE t_1 (f_1 INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, f_2 STRING DEFAULT V)";
                beforeEach(^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [db executeUpdate:differentSchemeSQL];
                    }];
                });
                it(@"Should fix scheme", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:nil];
                    }];
                    [[schemaSQL() should] equal:expectedSQL];
                });
            });
            context(@"More fields", ^{
                NSString *differentSchemeSQL =
                    @"CREATE TABLE t_1 (f_1 INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, f_2 STRING DEFAULT V, f_3 BLOB, f_4 STRING)";
                beforeEach(^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [db executeUpdate:differentSchemeSQL];
                    }];
                });
                it(@"Should fix scheme", ^{
                    [databaseQueue inDatabase:^(AMAFMDatabase * _Nonnull db) {
                        [controller enforceDatabaseConsistencyInDB:db onInconsistency:nil];
                    }];
                    [[schemaSQL() should] equal:expectedSQL];
                });
            });
        });
    });

});

SPEC_END

