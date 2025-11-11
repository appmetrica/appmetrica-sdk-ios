
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

SPEC_BEGIN(AMAIdentifierValidatorTests)

describe(@"AMAIdentifierValidator", ^{
    context(@"white validating numeric key", ^{
        it(@"should decline empty numeric key", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@""]) should] beNo];
        });

        it(@"should decline negative numeric key", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@"-123"]) should] beNo];
        });

        it(@"should decline rational numeric key", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@"1.231"]) should] beNo];
        });

        it(@"should decline numericalpha key", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@"123bsdfg"]) should] beNo];
        });

        it(@"should decline alphanumeric key", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@"bsdfg123"]) should] beNo];
        });

        it(@"should accept valid numeric keys", ^{
            [[theValue([AMAIdentifierValidator isValidNumericKey:@"2031123"]) should] beYes];
        });
    });

    context(@"white validating uuid key", ^{
        it(@"should decline empty uuid", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@""]) should] beNo];
        });

        it(@"should decline alfanumeric uuid", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@"123fasdf"]) should] beNo];
        });

        it(@"should decline unseparated uuid", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@"550e8400e29b41d4a716446655440000"]) should] beNo];
        });

        it(@"should decline uuid with insufficient symbols count", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@"550e840-e29b-41d4-a716-446655440000"]) should] beNo];
        });

        it(@"should decline uuid with extra symbols count", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@"550e8400-e29b-41d4-a716-4466554400000"]) should] beNo];
        });

        it(@"should accept valid uuid", ^{
            [[theValue([AMAIdentifierValidator isValidUUIDKey:@"550e8400-e29b-41d4-a716-446655440000"]) should] beYes];
        });
    });

    context(@"white validating identifier for vendor", ^{
        it(@"should decline empty identifier", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@""]) should] beNo];
        });

        it(@"should decline unseparated identifier", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@"550e8400e29b41d4a716446655440000"]) should] beNo];
        });

        it(@"should decline identifiers with insufficient symbols count", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@"550e8400-e29b41d4-a716-446655440000"]) should] beNo];
        });

        it(@"should decline identifiers with extra symbols count", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@"550e8400-e29b41d4-a7126-446655440000"]) should] beNo];
        });

        it(@"should decline one symbol identifier", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@"00000000-0000-0000-0000-000000000000"]) should] beNo];
        });

        it(@"should accept valid identifier", ^{
            [[theValue([AMAIdentifierValidator isValidVendorIdentifier:@"550e8400-e29b-41d4-a716-446655440000"]) should] beYes];
        });
    });
});

SPEC_END
