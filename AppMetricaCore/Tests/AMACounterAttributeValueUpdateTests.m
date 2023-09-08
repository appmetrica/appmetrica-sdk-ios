
#import <Kiwi/Kiwi.h>
#import "AMACounterAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMACounterAttributeValueUpdateTests)

describe(@"AMACounterAttributeValueUpdate", ^{

    NSInteger const delta = 23;

    AMAAttributeValue *__block value = nil;
    AMACounterAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
        update = [[AMACounterAttributeValueUpdate alloc] initWithDeltaValue:delta];
    });

    it(@"Should update existing value", ^{
        NSInteger previousValue = 42;
        value.counterValue = @(previousValue);
        [update applyToValue:value];
        [[value.counterValue should] equal:@(previousValue + delta)];
    });

    it(@"Should set new value if undefined", ^{
        [update applyToValue:value];
        [[value.counterValue should] equal:@(delta)];
    });

});

SPEC_END
