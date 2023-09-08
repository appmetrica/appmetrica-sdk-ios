
#import <Kiwi/Kiwi.h>
#import "AMAGenderAttribute.h"
#import "AMAStringAttribute.h"

SPEC_BEGIN(AMAGenderAttributeTests)

describe(@"AMAGenderAttribute", ^{

    AMAStringAttribute *__block stringAttribute = nil;
    AMAUserProfileUpdate *__block stringAttributeUpdate = nil;
    AMAGenderAttribute *__block attribute = nil;

    beforeEach(^{
        stringAttribute = [AMAStringAttribute nullMock];
        stringAttributeUpdate = [AMAUserProfileUpdate nullMock];
        attribute = [[AMAGenderAttribute alloc] initWithStringAttribute:stringAttribute];
    });

    context(@"With value", ^{
        beforeEach(^{
            [stringAttribute stub:@selector(withValue:) andReturn:stringAttributeUpdate];
        });
        context(@"Male", ^{
            AMAGenderType const genderType = AMAGenderTypeMale;
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"M"];
                [attribute withValue:genderType];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withValue:genderType] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Female", ^{
            AMAGenderType const genderType = AMAGenderTypeFemale;
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"F"];
                [attribute withValue:genderType];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withValue:genderType] should] equal:stringAttributeUpdate];
            });
        });
        context(@"Other", ^{
            AMAGenderType const genderType = AMAGenderTypeOther;
            it(@"Should request valid string attribute update", ^{
                [[stringAttribute should] receive:@selector(withValue:) withArguments:@"O"];
                [attribute withValue:genderType];
            });
            it(@"Should return string attribute update", ^{
                [[[attribute withValue:genderType] should] equal:stringAttributeUpdate];
            });
        });
    });
    context(@"With reset", ^{
        beforeEach(^{
            [stringAttribute stub:@selector(withValueReset) andReturn:stringAttributeUpdate];
        });
        it(@"Should request valid string attribute update", ^{
            [[stringAttribute should] receive:@selector(withValueReset)];
            [attribute withValueReset];
        });
        it(@"Should return string attribute update", ^{
            [[[attribute withValueReset] should] equal:stringAttributeUpdate];
        });
    });

});

SPEC_END
