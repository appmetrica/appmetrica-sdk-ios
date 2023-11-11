
#import <Kiwi/Kiwi.h>
#import "AMADatabaseHelper.h"
#import <AppMetrica_FMDB/AppMetrica_FMDB.h>

SPEC_BEGIN(AMADatabaseHelperTests)

describe(@"AMADatabaseHelper", ^{

    context(@"Description", ^{
        NSArray *const resultDictionaries = @[ @{@"foo": @"bar"}, @{@"a": @"b"} ];
        NSArray *const desriptions = @[ [resultDictionaries[0] description], [resultDictionaries[1] description] ];
        AMAFMResultSet *__block resultSet = nil;
        NSUInteger __block nextCallCount = 0;

        beforeEach(^{
            resultSet = [AMAFMResultSet nullMock];
            nextCallCount = 0;
            [resultSet stub:@selector(next) withBlock:^id(NSArray *params) {
                id result = theValue(nextCallCount < desriptions.count);
                ++nextCallCount;
                return result;
            }];
            [resultSet stub:@selector(resultDictionary) withBlock:^id(NSArray *params) {
                return resultDictionaries[nextCallCount - 1];
            }];
        });
        it(@"Should provide descriprion", ^{
            [[[AMADatabaseHelper eachResultsDescription:resultSet] should] equal:desriptions];
        });
        it(@"Should close result set", ^{
            [[resultSet should] receive:@selector(close)];
            [AMADatabaseHelper eachResultsDescription:resultSet];
        });
    });

    context(@"Intervals", ^{
        NSString *const key = @"x";
        NSMutableArray *__block values = nil;
        beforeEach(^{
            values = [NSMutableArray array];
        });

        it(@"Should return empty query for empty identifiers", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[]
                                                                               key:key
                                                                            values:values];
            [[query should] beEmpty];
            [[values should] beEmpty];
        });

        it(@"Should return one interval", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @2, @3, @4]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x >= ? AND x <= ?)"];
            [[values should] equal:@[@1, @4]];
        });
        it(@"Should return one single point", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x = ?)"];
            [[values should] equal:@[@1]];
        });
        it(@"Should return two intervals", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @2, @3, @7, @8]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x >= ? AND x <= ?) OR (x >= ? AND x <= ?)"];
            [[values should] equal:@[@1, @3, @7, @8]];
        });
        it(@"Should return one interval and single point", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @2, @3, @7]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x >= ? AND x <= ?) OR (x = ?)"];
            [[values should] equal:@[@1, @3, @7]];
        });
        it(@"Should return single point and one interval", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @6, @7, @8]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x = ?) OR (x >= ? AND x <= ?)"];
            [[values should] equal:@[@1, @6, @8]];
        });
        it(@"Should return three single points", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @5, @12]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x = ?) OR (x = ?) OR (x = ?)"];
            [[values should] equal:@[@1, @5, @12]];
        });
        it(@"Should return interval, single point and interval", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @2, @5, @7, @8, @9]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x >= ? AND x <= ?) OR (x = ?) OR (x >= ? AND x <= ?)"];
            [[values should] equal:@[@1, @2, @5, @7, @9]];
        });
        it(@"Should return single point, interval and single point", ^{
            NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @4, @5, @6, @8]
                                                                               key:key
                                                                            values:values];
            [[query should] equal:@"(x = ?) OR (x >= ? AND x <= ?) OR (x = ?)"];
            [[values should] equal:@[@1, @4, @6, @8]];
        });
        context(@"Unsorted", ^{
            it(@"Should return one interval", ^{
                NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@3, @2, @4, @1]
                                                                                   key:key
                                                                                values:values];
                [[query should] equal:@"(x >= ? AND x <= ?)"];
                [[values should] equal:@[@1, @4]];
            });
            it(@"Should return two intervals", ^{
                NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@3, @2, @7, @1, @8]
                                                                                   key:key
                                                                                values:values];
                [[query should] equal:@"(x >= ? AND x <= ?) OR (x >= ? AND x <= ?)"];
                [[values should] equal:@[@1, @3, @7, @8]];
            });
            it(@"Should return one interval and single point", ^{
                NSString *query = [AMADatabaseHelper intervalsWhereQueryForIdentifiers:@[@1, @3, @7, @2]
                                                                                   key:key
                                                                                values:values];
                [[query should] equal:@"(x >= ? AND x <= ?) OR (x = ?)"];
                [[values should] equal:@[@1, @3, @7]];
            });
        });
    });

});

SPEC_END

