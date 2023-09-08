
#import <Kiwi/Kiwi.h>
#import "AMAStringDatabaseKeyValueStorageConverter.h"
@import FMDB;

SPEC_BEGIN(AMAStringDatabaseKeyValueStorageConverterTests)

describe(@"AMAStringDatabaseKeyValueStorageConverter", ^{

    AMAStringDatabaseKeyValueStorageConverter *__block converter = nil;

    beforeEach(^{
        converter = [[AMAStringDatabaseKeyValueStorageConverter alloc] init];
    });

    context(@"BOOL", ^{
        it(@"Should store YES", ^{
            id object = [converter objectForBool:YES];
            [[theValue([converter boolForObject:object]) should] beYes];
        });
        it(@"Should store NO", ^{
            id object = [converter objectForBool:NO];
            [[theValue([converter boolForObject:object]) should] beNo];
        });
        context(@"Invalid string", ^{
            it(@"Should return NO for nil", ^{
                [[theValue([converter boolForObject:nil]) should] beNo];
            });
            it(@"Should return NO for empty string", ^{
                [[theValue([converter boolForObject:@""]) should] beNo];
            });
            it(@"Should return NO for unknown string", ^{
                [[theValue([converter boolForObject:@"BLABLA"]) should] beNo];
            });
        });
    });

    context(@"long long", ^{
        it(@"Should store zero", ^{
            long long const value = 0;
            id object = [converter objectForLongLong:value];
            [[theValue([converter longLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store small positive", ^{
            long long const value = 23;
            id object = [converter objectForLongLong:value];
            [[theValue([converter longLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store small negative", ^{
            long long const value = -23;
            id object = [converter objectForLongLong:value];
            [[theValue([converter longLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store big positive", ^{
            long long const value = 23000000000;
            id object = [converter objectForLongLong:value];
            [[theValue([converter longLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store big negative", ^{
            long long const value = -23000000000;
            id object = [converter objectForLongLong:value];
            [[theValue([converter longLongForObject:object]) should] equal:theValue(value)];
        });
        context(@"Invalid string", ^{
            it(@"Should return 0 for nil", ^{
                [[theValue([converter longLongForObject:nil]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for empty string", ^{
                [[theValue([converter longLongForObject:@""]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for non-number string", ^{
                [[theValue([converter longLongForObject:@"NOT-A-NUMBER"]) should] equal:theValue(0)];
            });
        });
    });
         
    context(@"unsigned long long", ^{
        it(@"Should store zero", ^{
            unsigned long long const value = 0;
            id object = [converter objectForUnsignedLongLong:value];
            [[theValue([converter unsignedLongLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store small positive", ^{
            unsigned long long const value = 23;
            id object = [converter objectForUnsignedLongLong:value];
            [[theValue([converter unsignedLongLongForObject:object]) should] equal:theValue(value)];
        });
        it(@"Should store big positive", ^{
            unsigned long long const value = ULLONG_MAX;
            id object = [converter objectForUnsignedLongLong:value];
            [[theValue([converter unsignedLongLongForObject:object]) should] equal:theValue(value)];
        });
        context(@"Invalid string", ^{
            it(@"Should raise for nil", ^{
                [[theBlock(^{ [converter unsignedLongLongForObject:nil]; }) should] raise];
            });
            it(@"Should raise for empty string", ^{
                [[theBlock(^{ [converter unsignedLongLongForObject:@""]; }) should] raise];
            });
            it(@"Should raise for non-number string", ^{
                [[theBlock(^{ [converter unsignedLongLongForObject:@"NOT-A-NUMBER"]; }) should] raise];
            });
            it(@"Should raise for numbers bigger than ULLONG_MAX", ^{
                [[theBlock(^{ [converter unsignedLongLongForObject:@"18446744073709551616"]; }) should] raise];
            });
        });
    });

    context(@"double", ^{
        double const EXPECTED_DELTA = 1e-10;

        it(@"Should store zero", ^{
            double const value = 0.0;
            id object = [converter objectForDouble:value];
            [[theValue([converter doubleForObject:object]) should] equal:value withDelta:EXPECTED_DELTA];
        });
        it(@"Should store small double", ^{
            double const value = 0.00123; // String converter can't handle really small doubles
            id object = [converter objectForDouble:value];
            [[theValue([converter doubleForObject:object]) should] equal:value withDelta:EXPECTED_DELTA];
        });
        it(@"Should store big double", ^{
            double const value = 23012012012.012012012;
            id object = [converter objectForDouble:value];
            [[theValue([converter doubleForObject:object]) should] equal:value withDelta:EXPECTED_DELTA];
        });
        context(@"Invalid string", ^{
            it(@"Should return 0 for nil", ^{
                [[theValue([converter doubleForObject:nil]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return 0 for empty string", ^{
                [[theValue([converter doubleForObject:@""]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return value for integer string", ^{
                [[theValue([converter doubleForObject:@"123"]) should] equal:123.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return 0 for non-number string", ^{
                [[theValue([converter doubleForObject:@"NOT-A-NUMBER"]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
        });
    });

    context(@"NSDate", ^{
        void (^datesShouldBeEqual)(NSDate *first, NSDate *second) = ^(NSDate *first, NSDate *second) {
            const double delta = 0.001; // String converter can't store precsise time
            NSTimeInterval timeFromReferenceDate = first.timeIntervalSinceReferenceDate;
            [[theValue(timeFromReferenceDate) should] equal:second.timeIntervalSinceReferenceDate withDelta:delta];
        };
        it(@"Should store current date", ^{
            NSDate *const value = [NSDate date];
            id object = [converter objectForDate:value];
            datesShouldBeEqual([converter dateForObject:object], value);
        });
        it(@"Should store small date", ^{
            NSDate * const value = [NSDate dateWithTimeIntervalSince1970:23.0];
            id object = [converter objectForDate:value];
            datesShouldBeEqual([converter dateForObject:object], value);
        });
        it(@"Should store big date", ^{
            NSDate * const value = [NSDate dateWithTimeIntervalSince1970:23000000000.023];
            id object = [converter objectForDate:value];
            datesShouldBeEqual([converter dateForObject:object], value);
        });
        context(@"Invalid string", ^{
            it(@"Should return nil for nil", ^{
                [[[converter dateForObject:nil] should] beNil];
            });
            it(@"Should return nil for empty string", ^{
                [[[converter dateForObject:@""] should] beNil];
            });
        });
    });

    context(@"NSString", ^{
        it(@"Should store empty string", ^{
            NSString *const value = @"";
            id object = [converter objectForString:value];
            [[[converter stringForObject:object] should] equal:value];
        });
        it(@"Should store normal string", ^{
            NSString *const value = @"STRING";
            id object = [converter objectForString:value];
            [[[converter stringForObject:object] should] equal:value];
        });
        context(@"Invalid string", ^{
            it(@"Should return nil for nil", ^{
                [[[converter stringForObject:nil] should] beNil];
            });
            it(@"Should return empty string for empty string", ^{
                [[[converter stringForObject:@""] should] beEmpty];
            });
        });
    });

    context(@"NSData", ^{
        it(@"Should store empty data", ^{
            NSData *const value = [NSData data];
            id object = [converter objectForData:value];
            [[[converter dataForObject:object] should] equal:value];
        });
        it(@"Should store normal data", ^{
            NSData *const value = [@"DATA" dataUsingEncoding:NSUTF8StringEncoding];
            id object = [converter objectForData:value];
            [[[converter dataForObject:object] should] equal:value];
        });
        context(@"Invalid string", ^{
            it(@"Should return nil for nil", ^{
                [[[converter dataForObject:nil] should] beNil];
            });
            it(@"Should return empty data for empty string", ^{
                [[[converter dataForObject:@""] should] beEmpty];
            });
            it(@"Should return nil for invalid base64", ^{
                [[[converter dataForObject:@"NOT-A-BASE64-STRING"] should] beNil];
            });
        });
    });

});

SPEC_END

