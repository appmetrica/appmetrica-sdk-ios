
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStringEventValue.h"

SPEC_BEGIN(AMAStringEventValueTests)

describe(@"AMAStringEventValue", ^{

    AMAStringEventValue *__block value = nil;

    context(@"Empty string", ^{
        NSString *const valueString = @"";
        beforeEach(^{
            value = [[AMAStringEventValue alloc] initWithValue:valueString];
        });
        it(@"Should be empty", ^{
            [[theValue(value.empty) should] beYes];
        });
        it(@"Should return empty data", ^{
            [[[value dataWithError:nil] should] beEmpty];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [value dataWithError:&error];
            [[error should] beNil];
        });
        it(@"Should return no encryption type", ^{
            [[theValue(value.encryptionType) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
        });
    });

    context(@"Non-empty string", ^{
        NSString *const valueString = @"VALUE";
        beforeEach(^{
            value = [[AMAStringEventValue alloc] initWithValue:valueString];
        });
        it(@"Should be empty", ^{
            [[theValue(value.empty) should] beNo];
        });
        it(@"Should return empty data", ^{
            [[[value dataWithError:nil] should] equal:[valueString dataUsingEncoding:NSUTF8StringEncoding]];
        });
        it(@"Should not fill error", ^{
            NSError *error = nil;
            [value dataWithError:&error];
            [[error should] beNil];
        });
        it(@"Should return no encryption type", ^{
            [[theValue(value.encryptionType) should] equal:theValue(AMAEventEncryptionTypeNoEncryption)];
        });
    });
    
    it(@"Should conform to AMAEventValueProtocol", ^{
        [[value should] conformToProtocol:@protocol(AMAEventValueProtocol)];
    });
});

SPEC_END

