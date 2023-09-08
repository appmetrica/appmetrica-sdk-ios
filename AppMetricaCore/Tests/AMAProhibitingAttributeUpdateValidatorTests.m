
#import <Kiwi/Kiwi.h>
#import "AMAProhibitingAttributeUpdateValidator.h"
#import "AMAUserProfileLogger.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileModel.h"

SPEC_BEGIN(AMAProhibitingAttributeUpdateValidatorTests)

describe(@"AMAProhibitingAttributeUpdateValidator", ^{

    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAUserProfileModel *__block model = nil;
    AMAProhibitingAttributeUpdateValidator *__block validator = nil;

    beforeEach(^{
        [AMAUserProfileLogger stub:@selector(logForbiddenAttributeNamePrefixWithName:forbiddenPrefix:)];
        attributeUpdate = [AMAAttributeUpdate nullMock];
        model = [AMAUserProfileModel nullMock];
    });

    context(@"Non-nil block", ^{
        AMAAttributeUpdate *__block loggedUpdate = nil;

        beforeEach(^{
            validator = [[AMAProhibitingAttributeUpdateValidator alloc] initWithLogBlock:^(AMAAttributeUpdate *update) {
                loggedUpdate = update;
            }];
        });
        it(@"Should return NO", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beNo];
        });
        it(@"Should call log block", ^{
            [validator validateUpdate:attributeUpdate model:model];
            [[loggedUpdate should] equal:attributeUpdate];
        });
    });
    context(@"Nil block", ^{
        beforeEach(^{
            validator = [[AMAProhibitingAttributeUpdateValidator alloc] initWithLogBlock:nil];
        });
        it(@"Should return NO", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beNo];
        });
        it(@"Should not raise", ^{
            [[theBlock(^{
                [validator validateUpdate:attributeUpdate model:model];
            }) shouldNot] raise];
        });
    });

});

SPEC_END
