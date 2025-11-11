
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMABinaryDatabaseKeyValueStorageConverter.h"

SPEC_BEGIN(AMABinaryDatabaseKeyValueStorageConverterTests)

describe(@"AMABinaryDatabaseKeyValueStorageConverter", ^{

    AMABinaryDatabaseKeyValueStorageConverter *__block converter = nil;

    beforeEach(^{
        converter = [[AMABinaryDatabaseKeyValueStorageConverter alloc] init];
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
        context(@"Invalid data", ^{
            it(@"Should return NO for nil", ^{
                [[theValue([converter boolForObject:nil]) should] beNo];
            });
            it(@"Should return NO for zero-bytes data", ^{
                [[theValue([converter boolForObject:[NSData data]]) should] beNo];
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
        context(@"Invalid data", ^{
            it(@"Should return 0 for nil", ^{
                [[theValue([converter longLongForObject:nil]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for zero-bytes data", ^{
                [[theValue([converter longLongForObject:[NSData data]]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for 7-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter longLongForObject:object]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for 9-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter longLongForObject:object]) should] equal:theValue(0)];
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
        context(@"Invalid data", ^{
            it(@"Should return 0 for nil", ^{
                [[theValue([converter unsignedLongLongForObject:nil]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for zero-bytes data", ^{
                [[theValue([converter unsignedLongLongForObject:[NSData data]]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for 7-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter unsignedLongLongForObject:object]) should] equal:theValue(0)];
            });
            it(@"Should return 0 for 9-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter unsignedLongLongForObject:object]) should] equal:theValue(0)];
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
            double const value = 0.000000123;
            id object = [converter objectForDouble:value];
            [[theValue([converter doubleForObject:object]) should] equal:value withDelta:EXPECTED_DELTA];
        });
        it(@"Should store big double", ^{
            double const value = 23012012012.012012012;
            id object = [converter objectForDouble:value];
            [[theValue([converter doubleForObject:object]) should] equal:value withDelta:EXPECTED_DELTA];
        });
        context(@"Invalid data", ^{
            it(@"Should return 0 for nil", ^{
                [[theValue([converter doubleForObject:nil]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return 0 for zero-bytes data", ^{
                [[theValue([converter doubleForObject:[NSData data]]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return 0 for 7-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter doubleForObject:object]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
            it(@"Should return 0 for 9-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[theValue([converter doubleForObject:object]) should] equal:0.0 withDelta:EXPECTED_DELTA];
            });
        });
    });

    context(@"NSDate", ^{
        it(@"Should store current date", ^{
            NSDate *const value = [NSDate date];
            id object = [converter objectForDate:value];
            [[[converter dateForObject:object] should] equal:value];
        });
        it(@"Should store small date", ^{
            NSDate * const value = [NSDate dateWithTimeIntervalSince1970:23.0];
            id object = [converter objectForDate:value];
            [[[converter dateForObject:object] should] equal:value];
        });
        it(@"Should store big date", ^{
            NSDate * const value = [NSDate dateWithTimeIntervalSince1970:23000000000.023];
            id object = [converter objectForDate:value];
            [[[converter dateForObject:object] should] equal:value];
        });
        context(@"Invalid data", ^{
            it(@"Should return nil for nil", ^{
                [[[converter dateForObject:nil] should] beNil];
            });
            it(@"Should return nil for zero-bytes data", ^{
                [[[converter dateForObject:[NSData data]] should] beNil];
            });
            it(@"Should return nil for 7-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[[converter dateForObject:object] should] beNil];
            });
            it(@"Should return nil for 9-bytes data", ^{
                const unsigned char dataBytes[] = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
                NSData *object = [NSData dataWithBytes:dataBytes length:7];
                [[[converter dateForObject:object] should] beNil];
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
        context(@"Invalid data", ^{
            it(@"Should return nil for nil", ^{
                [[[converter stringForObject:nil] should] beNil];
            });
            it(@"Should return empty string for zero-bytes data", ^{
                [[[converter stringForObject:[NSData data]] should] beEmpty];
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
        context(@"Invalid data", ^{
            it(@"Should return nil for nil", ^{
                [[[converter dataForObject:nil] should] beNil];
            });
        });
    });

    it(@"Should conform to AMAKeyValueStorageConverting", ^{
        [[converter should] conformToProtocol:@protocol(AMAKeyValueStorageConverting)];
    });
});

SPEC_END
