
#import <Kiwi/Kiwi.h>
#import "AMANumberAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMANumberAttributeValueUpdateTests)

describe(@"AMANumberAttributeValueUpdate", ^{

    double const numberValue = 23;

    AMAAttributeValue *__block value = nil;
    AMANumberAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
        update = [[AMANumberAttributeValueUpdate alloc] initWithValue:numberValue];
    });

    it(@"Should update existing value", ^{
        NSInteger previousValue = 42;
        value.numberValue = @(previousValue);
        [update applyToValue:value];
        [[value.numberValue should] equal:@(numberValue)];
    });

    it(@"Should set new value if undefined", ^{
        [update applyToValue:value];
        [[value.numberValue should] equal:@(numberValue)];
    });

    it(@"Should conform to AMAAttributeValueUpdate", ^{
        [[update should] conformToProtocol:@protocol(AMAAttributeValueUpdate)];
    });
});

SPEC_END
