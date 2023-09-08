
#import <Kiwi/Kiwi.h>
#import "AMAInvalidUserProfileUpdateFactory.h"
#import "AMAProhibitingAttributeUpdateValidator.h"
#import "AMAUserProfileUpdate.h"
#import "AMAUserProfileLogger.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAInvalidUserProfileUpdateFactoryTests)

describe(@"AMAInvalidUserProfileUpdateFactory", ^{

    NSString *const name = @"ATTRIBUTE_NAME";

    AMAProhibitingAttributeUpdateLogBlock __block logBlock = nil;
    AMAUserProfileUpdate *__block update = nil;
    AMAProhibitingAttributeUpdateValidator *__block validator = nil;

    beforeEach(^{
        update = [AMAUserProfileUpdate stubbedNullMockForInit:@selector(initWithAttributeUpdate:validators:)];
        validator = [AMAProhibitingAttributeUpdateValidator stubbedNullMockForInit:@selector(initWithLogBlock:)];
        [validator stub:@selector(initWithLogBlock:) withBlock:^id(NSArray *params) {
            logBlock = params[0];
            return validator;
        }];
    });

    context(@"Date", ^{
        beforeEach(^{
            [AMAUserProfileLogger stub:@selector(logInvalidDateWithAttributeName:)];
        });
        it(@"Should create validator with non-nil log block", ^{
            [AMAInvalidUserProfileUpdateFactory invalidDateUpdateWithAttributeName:name];
            [[logBlock should] beNonNil];
        });
        it(@"Should create validator with valid log block", ^{
            [AMAInvalidUserProfileUpdateFactory invalidDateUpdateWithAttributeName:name];
            [[AMAUserProfileLogger should] receive:@selector(logInvalidDateWithAttributeName:)
                                     withArguments:name];
            logBlock(nil);
        });
        it(@"Should create user profile update", ^{
            [[update should] receive:@selector(initWithAttributeUpdate:validators:)
                       withArguments:nil, @[ validator ]];
            [AMAInvalidUserProfileUpdateFactory invalidDateUpdateWithAttributeName:name];
        });
        it(@"Should return update", ^{
            [[[AMAInvalidUserProfileUpdateFactory invalidDateUpdateWithAttributeName:name] should] equal:update];
        });
    });
    context(@"Gender", ^{
        beforeEach(^{
            [AMAUserProfileLogger stub:@selector(logInvalidGenderTypeWithAttributeName:)];
        });
        it(@"Should create validator with non-nil log block", ^{
            [AMAInvalidUserProfileUpdateFactory invalidGenderTypeUpdateWithAttributeName:name];
            [[logBlock should] beNonNil];
        });
        it(@"Should create validator with valid log block", ^{
            [AMAInvalidUserProfileUpdateFactory invalidGenderTypeUpdateWithAttributeName:name];
            [[AMAUserProfileLogger should] receive:@selector(logInvalidGenderTypeWithAttributeName:)
                                     withArguments:name];
            logBlock(nil);
        });
        it(@"Should create user profile update", ^{
            [[update should] receive:@selector(initWithAttributeUpdate:validators:)
                       withArguments:nil, @[ validator ]];
            [AMAInvalidUserProfileUpdateFactory invalidGenderTypeUpdateWithAttributeName:name];
        });
        it(@"Should return update", ^{
            [[[AMAInvalidUserProfileUpdateFactory invalidGenderTypeUpdateWithAttributeName:name] should] equal:update];
        });
    });

});

SPEC_END
