
#import <Kiwi/Kiwi.h>
#import "AMAStringAttributeTruncatorFactory.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAStringAttributeTruncator.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAStringAttributeTruncatorFactoryTests)

describe(@"AMAStringAttributeTruncatorFactory", ^{

    AMALengthStringTruncator *__block lengthTruncator = nil;
    AMAPermissiveTruncator *__block permissiveTruncator = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;

    beforeEach(^{
        lengthTruncator = [AMALengthStringTruncator stubbedNullMockForInit:@selector(initWithMaxLength:)];
        permissiveTruncator = [AMAPermissiveTruncator stubbedNullMockForDefaultInit];
        truncationProvider =
            [AMAStringAttributeTruncationProvider stubbedNullMockForInit:@selector(initWithUnderlyingTruncator:)];
    });

    context(@"Name", ^{
        it(@"Should create length truncator", ^{
            [[lengthTruncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(100)];
            [AMAStringAttributeTruncatorFactory nameTruncationProvider];
        });
        it(@"Should create truncation provider", ^{
            [[truncationProvider should] receive:@selector(initWithUnderlyingTruncator:) withArguments:lengthTruncator];
            [AMAStringAttributeTruncatorFactory nameTruncationProvider];
        });
        it(@"Should return created provider", ^{
            [[[AMAStringAttributeTruncatorFactory nameTruncationProvider] should] equal:truncationProvider];
        });
    });
    context(@"Gender", ^{
        it(@"Should create length truncator", ^{
            [[permissiveTruncator should] receive:@selector(init)];
            [AMAStringAttributeTruncatorFactory genderTruncationProvider];
        });
        it(@"Should create truncation provider", ^{
            [[truncationProvider should] receive:@selector(initWithUnderlyingTruncator:)
                                   withArguments:permissiveTruncator];
            [AMAStringAttributeTruncatorFactory genderTruncationProvider];
        });
        it(@"Should return created provider", ^{
            [[[AMAStringAttributeTruncatorFactory genderTruncationProvider] should] equal:truncationProvider];
        });
    });
    context(@"Birth date", ^{
        it(@"Should create length truncator", ^{
            [[permissiveTruncator should] receive:@selector(init)];
            [AMAStringAttributeTruncatorFactory birthDateTruncationProvider];
        });
        it(@"Should create truncation provider", ^{
            [[truncationProvider should] receive:@selector(initWithUnderlyingTruncator:)
                                   withArguments:permissiveTruncator];
            [AMAStringAttributeTruncatorFactory birthDateTruncationProvider];
        });
        it(@"Should return created provider", ^{
            [[[AMAStringAttributeTruncatorFactory birthDateTruncationProvider] should] equal:truncationProvider];
        });
    });
    context(@"Custom string", ^{
        it(@"Should create length truncator", ^{
            [[lengthTruncator should] receive:@selector(initWithMaxLength:) withArguments:theValue(200)];
            [AMAStringAttributeTruncatorFactory customStringTruncationProvider];
        });
        it(@"Should create truncation provider", ^{
            [[truncationProvider should] receive:@selector(initWithUnderlyingTruncator:) withArguments:lengthTruncator];
            [AMAStringAttributeTruncatorFactory customStringTruncationProvider];
        });
        it(@"Should return created provider", ^{
            [[[AMAStringAttributeTruncatorFactory customStringTruncationProvider] should] equal:truncationProvider];
        });
    });

});

SPEC_END
