
#import <Kiwi/Kiwi.h>
#import "AMAResetAwareAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMAResetAwareAttributeValueUpdateTests)

describe(@"AMAResetAwareAttributeValueUpdate", ^{

    AMAAttributeValue *__block value = nil;
    NSObject<AMAAttributeValueUpdate> *__block underlyingUpdate = nil;
    AMAResetAwareAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
        underlyingUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
    });

    context(@"Reset", ^{
        beforeEach(^{
            update = [[AMAResetAwareAttributeValueUpdate alloc] initWithIsReset:YES
                                                                underlyingValueUpdate:underlyingUpdate];
        });
        context(@"Value was reset", ^{
            beforeEach(^{
                value.reset = @YES;
            });
            it(@"Should not update flag with NO", ^{
                [[value shouldNot] receive:@selector(setReset:) withArguments:@NO];
                [update applyToValue:value];
            });
            it(@"Should not apply underlying update", ^{
                [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                [update applyToValue:value];
            });
        });
        context(@"Value was set", ^{
            beforeEach(^{
                value.reset = @NO;
                value.stringValue = @"STRING";
                value.numberValue = @23;
                value.counterValue = @32;
            });
            it(@"Should update flag", ^{
                [[value should] receive:@selector(setReset:) withArguments:@YES];
                [update applyToValue:value];
            });
            it(@"Should clean string value", ^{
                [update applyToValue:value];
                [[value.stringValue should] beNil];
            });
            it(@"Should clean number value", ^{
                [update applyToValue:value];
                [[value.numberValue should] beNil];
            });
            it(@"Should clean counter value", ^{
                [update applyToValue:value];
                [[value.counterValue should] beNil];
            });
            it(@"Should not apply underlying update", ^{
                [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                [update applyToValue:value];
            });
        });
    });
    context(@"Not reset", ^{
        beforeEach(^{
            update = [[AMAResetAwareAttributeValueUpdate alloc] initWithIsReset:NO
                                                                underlyingValueUpdate:underlyingUpdate];
        });
        context(@"Value was reset", ^{
            beforeEach(^{
                value.reset = @YES;
            });
            it(@"Should update flag with NO", ^{
                [[value should] receive:@selector(setReset:) withArguments:@NO];
                [update applyToValue:value];
            });
            it(@"Should apply underlying update", ^{
                [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToValue:value];
            });
        });
        context(@"Value was set", ^{
            beforeEach(^{
                value.reset = @NO;
                value.stringValue = @"STRING";
                value.numberValue = @23;
                value.counterValue = @32;
            });
            it(@"Should not update flag with YES", ^{
                [[value shouldNot] receive:@selector(setReset:) withArguments:@YES];
                [update applyToValue:value];
            });
            it(@"Should apply underlying update", ^{
                [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToValue:value];
            });
        });
    });

});

SPEC_END
