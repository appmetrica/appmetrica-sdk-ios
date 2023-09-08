
#import <Kiwi/Kiwi.h>
#import "AMACore.h"
#import "AMATypeSafeDictionaryHelper.h"
#import "AMAErrorsFactory.h"

static NSNumber *extractor(id value, NSError **error)
{
    AMA_GUARD_ENSURE_TYPE_OR_RETURN(NSNumber, varName, value);
    return varName;
}

SPEC_BEGIN(AMATypeSafeDictionaryHelperTests)

describe(@"AMATypeSafeDictionaryHelper", ^{

    NSError *__block error = nil;

    beforeEach(^{
        error = nil;
    });

    __auto_type errorWithDescription = ^NSError *(NSString *description) {
        return [NSError errorWithDomain:@"AppMetricaInternalErrorDomain"
                                   code:3000
                               userInfo:@{NSLocalizedDescriptionKey : description}];
    };

    context(@"Number", ^{
        id value = @23;
        it(@"Should return correct value", ^{
            [[extractor(value, &error) should] equal:value];
        });
        it(@"Should not fill error", ^{
            extractor(value, &error);
            [[error should] beNil];
        });
    });

    context(@"NSString", ^{
        id value = @"STR";
        it(@"Should return nil", ^{
            [[extractor(value, &error) should] beNil];
        });
        it(@"Should fill error", ^{
            extractor(value, &error);
            [[error should] equal:errorWithDescription(@"Invalid type for varName: expected NSNumber but was __NSCFConstantString")];
        });
    });

    context(@"NSNull", ^{
        id value = [NSNull null];
        it(@"Should return nil", ^{
            [[extractor(value, &error) should] beNil];
        });
        it(@"Should not fill error", ^{
            extractor(value, &error);
            [[error should] beNil];
        });
    });

});

SPEC_END

