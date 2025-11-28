
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAttributeUpdateNameLengthValidator.h"
#import "AMAUserProfileLogger.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileModel.h"

SPEC_BEGIN(AMAAttributeUpdateNameLengthValidatorTests)

describe(@"AMAAttributeUpdateNameLengthValidator", ^{

    NSUInteger const limit = 10;

    NSString *__block name = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAUserProfileModel *__block model = nil;
    AMAAttributeUpdateNameLengthValidator *__block validator = nil;

    beforeEach(^{
        [AMAUserProfileLogger stub:@selector(logAttributeNameTooLong:)];
        attributeUpdate = [AMAAttributeUpdate nullMock];
        model = [AMAUserProfileModel nullMock];
        validator = [[AMAAttributeUpdateNameLengthValidator alloc] initWithLengthLimit:limit];
    });
    afterEach(^{
        [AMAUserProfileLogger clearStubs];
    });

    it(@"Should use valid arguments in default initializer", ^{
        validator = [AMAAttributeUpdateNameLengthValidator alloc];
        [[validator should] receive:@selector(initWithLengthLimit:) withArguments:theValue(200)];
        id some __unused = [validator init];
    });
    context(@"Short name", ^{
        beforeEach(^{
            name = @"SHORT";
            [attributeUpdate stub:@selector(name) andReturn:name];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
        });
        it(@"Should not log", ^{
            [[AMAUserProfileLogger shouldNot] receive:@selector(logAttributeNameTooLong:)];
            [validator validateUpdate:attributeUpdate model:model];
        });
    });
    context(@"Long name", ^{
        beforeEach(^{
            name = @"LONG_______";
            [attributeUpdate stub:@selector(name) andReturn:name];
        });
        it(@"Should return NO", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beNo];
        });
        it(@"Should log", ^{
            [[AMAUserProfileLogger should] receive:@selector(logAttributeNameTooLong:) withArguments:name];
            [validator validateUpdate:attributeUpdate model:model];
        });
    });

    it(@"Should conform to AMAAttributeUpdateValidating", ^{
        [[validator should] conformToProtocol:@protocol(AMAAttributeUpdateValidating)];
    });
});

SPEC_END
