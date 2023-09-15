
#import <Kiwi/Kiwi.h>
#import "AMABoolAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMABoolAttributeValueUpdateTests)

describe(@"AMABoolAttributeValueUpdate", ^{

    AMAAttributeValue *__block value = nil;
    AMABoolAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
    });

    context(@"YES", ^{
        BOOL const boolValue = YES;
        beforeEach(^{
            update = [[AMABoolAttributeValueUpdate alloc] initWithValue:boolValue];
        });
        it(@"Should update existing value", ^{
            value.boolValue = @(boolValue == NO);
            [update applyToValue:value];
            [[value.boolValue should] equal:@(boolValue)];
        });
        it(@"Should set new value if undefined", ^{
            [update applyToValue:value];
            [[value.boolValue should] equal:@(boolValue)];
        });
    });
    context(@"NO", ^{
        BOOL const boolValue = NO;
        beforeEach(^{
            update = [[AMABoolAttributeValueUpdate alloc] initWithValue:boolValue];
        });
        it(@"Should update existing value", ^{
            value.boolValue = @(boolValue == NO);
            [update applyToValue:value];
            [[value.boolValue should] equal:@(boolValue)];
        });
        it(@"Should set new value if undefined", ^{
            [update applyToValue:value];
            [[value.boolValue should] equal:@(boolValue)];
        });
    });

    it(@"Should conform to AMAAttributeValueUpdate", ^{
        [[update should] conformToProtocol:@protocol(AMAAttributeValueUpdate)];
    });
});

SPEC_END
