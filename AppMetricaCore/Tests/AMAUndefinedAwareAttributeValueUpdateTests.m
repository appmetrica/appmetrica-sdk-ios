
#import <Kiwi/Kiwi.h>
#import "AMAUndefinedAwareAttributeValueUpdate.h"
#import "AMAAttributeValue.h"

SPEC_BEGIN(AMAUndefinedAwareAttributeValueUpdateTests)

describe(@"AMAUndefinedAwareAttributeValueUpdate", ^{

    AMAAttributeValue *__block value = nil;
    NSObject<AMAAttributeValueUpdate> *__block underlyingUpdate = nil;
    AMAUndefinedAwareAttributeValueUpdate *__block update = nil;

    beforeEach(^{
        value = [[AMAAttributeValue alloc] init];
        underlyingUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
    });

    context(@"Undefined", ^{
        beforeEach(^{
            update = [[AMAUndefinedAwareAttributeValueUpdate alloc] initWithIsUndefined:YES
                                                                  underlyingValueUpdate:underlyingUpdate];
        });
        context(@"Value was undefined", ^{
            it(@"Should update flag", ^{
                [[value should] receive:@selector(setSetIfUndefined:) withArguments:@YES];
                [update applyToValue:value];
            });
            it(@"Should apply underlying update", ^{
                [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToValue:value];
            });
        });
        context(@"Value was not undefined", ^{
            context(@"String", ^{
                beforeEach(^{
                    value.stringValue = @"SOME";
                });
                it(@"Should not update flag", ^{
                    [[value shouldNot] receive:@selector(setSetIfUndefined:)];
                    [update applyToValue:value];
                });
                it(@"Should not apply underlying update", ^{
                    [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                    [update applyToValue:value];
                });
            });
            context(@"Number", ^{
                beforeEach(^{
                    value.numberValue = @23;
                });
                it(@"Should not update flag", ^{
                    [[value shouldNot] receive:@selector(setSetIfUndefined:)];
                    [update applyToValue:value];
                });
                it(@"Should not apply underlying update", ^{
                    [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                    [update applyToValue:value];
                });
            });
            context(@"Counter", ^{
                beforeEach(^{
                    value.counterValue = @42;
                });
                it(@"Should not update flag", ^{
                    [[value shouldNot] receive:@selector(setSetIfUndefined:)];
                    [update applyToValue:value];
                });
                it(@"Should not apply underlying update", ^{
                    [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                    [update applyToValue:value];
                });
            });
            context(@"Bool", ^{
                beforeEach(^{
                    value.boolValue = @YES;
                });
                it(@"Should not update flag", ^{
                    [[value shouldNot] receive:@selector(setSetIfUndefined:)];
                    [update applyToValue:value];
                });
                it(@"Should not apply underlying update", ^{
                    [[underlyingUpdate shouldNot] receive:@selector(applyToValue:)];
                    [update applyToValue:value];
                });
            });
        });
    });
    context(@"Not undefined", ^{
        beforeEach(^{
            update = [[AMAUndefinedAwareAttributeValueUpdate alloc] initWithIsUndefined:NO
                                                                  underlyingValueUpdate:underlyingUpdate];
        });
        context(@"Value was undefined", ^{
            it(@"Should update flag", ^{
                [[value should] receive:@selector(setSetIfUndefined:) withArguments:@NO];
                [update applyToValue:value];
            });
            it(@"Should apply underlying update", ^{
                [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToValue:value];
            });
        });
        context(@"Value was not undefined", ^{
            context(@"String", ^{
                beforeEach(^{
                    value.stringValue = @"SOME";
                });
                it(@"Should update flag", ^{
                    [[value should] receive:@selector(setSetIfUndefined:) withArguments:@NO];
                    [update applyToValue:value];
                });
                it(@"Should apply underlying update", ^{
                    [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                    [update applyToValue:value];
                });
            });
            context(@"Number", ^{
                beforeEach(^{
                    value.numberValue = @23;
                });
                it(@"Should update flag", ^{
                    [[value should] receive:@selector(setSetIfUndefined:) withArguments:@NO];
                    [update applyToValue:value];
                });
                it(@"Should apply underlying update", ^{
                    [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                    [update applyToValue:value];
                });
            });
            context(@"Counter", ^{
                beforeEach(^{
                    value.counterValue = @42;
                });
                it(@"Should update flag", ^{
                    [[value should] receive:@selector(setSetIfUndefined:) withArguments:@NO];
                    [update applyToValue:value];
                });
                it(@"Should apply underlying update", ^{
                    [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                    [update applyToValue:value];
                });
            });
            context(@"Bool", ^{
                beforeEach(^{
                    value.boolValue = @YES;
                });
                it(@"Should update flag", ^{
                    [[value should] receive:@selector(setSetIfUndefined:) withArguments:@NO];
                    [update applyToValue:value];
                });
                it(@"Should apply underlying update", ^{
                    [[underlyingUpdate should] receive:@selector(applyToValue:) withArguments:value];
                    [update applyToValue:value];
                });
            });
        });
    });

    it(@"Should conform to AMAAttributeValueUpdate", ^{
        [[update should] conformToProtocol:@protocol(AMAAttributeValueUpdate)];
    });
});

SPEC_END
