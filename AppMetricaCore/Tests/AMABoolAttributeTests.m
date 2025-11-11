
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMABoolAttribute.h"
#import "AMACategoricalAttributeValueUpdateFactory.h"
#import "AMABoolAttributeValueUpdate.h"
#import "AMAUserProfileUpdateProviding.h"
#import "AMAAttributeUpdate.h"

SPEC_BEGIN(AMABoolAttributeTests)

describe(@"AMABoolAttribute", ^{

    NSString *const name = @"ATTRIBUTE_NAME";

    AMABoolAttributeValueUpdate *__block boolValueUpdate = nil;
    NSObject<AMAUserProfileUpdateProviding> *__block updateProvider = nil;
    AMACategoricalAttributeValueUpdateFactory *__block factory = nil;
    NSObject<AMAAttributeValueUpdate> *__block categoricalValueUpdate = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMABoolAttribute *__block attribute = nil;

    beforeEach(^{
        boolValueUpdate = [AMABoolAttributeValueUpdate stubbedNullMockForInit:@selector(initWithValue:)];
        factory = [AMACategoricalAttributeValueUpdateFactory nullMock];
        categoricalValueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
        updateProvider = [KWMock nullMockForProtocol:@protocol(AMAUserProfileUpdateProviding)];
        userProfileUpdate = [AMAUserProfileUpdate nullMock];
        [updateProvider stub:@selector(updateWithAttributeName:type:valueUpdate:) andReturn:userProfileUpdate];
        attribute = [[AMABoolAttribute alloc] initWithName:name
                                 userProfileUpdateProvider:updateProvider
                                  categoricalUpdateFactory:factory];
    });

    context(@"Update with value", ^{
        beforeEach(^{
            [factory stub:@selector(updateWithUnderlyingUpdate:) andReturn:categoricalValueUpdate];
        });
        context(@"YES", ^{
            BOOL const value = YES;
            it(@"Should create bool value update", ^{
                [[boolValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
                [attribute withValue:value];
            });
            it(@"Should create categorical value update", ^{
                [[factory should] receive:@selector(updateWithUnderlyingUpdate:) withArguments:boolValueUpdate];
                [attribute withValue:value];
            });
            it(@"Should create attribute update", ^{
                [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                                   withArguments:name, theValue(AMAAttributeTypeBool), categoricalValueUpdate];
                [attribute withValue:value];
            });
            it(@"Should return attribute update", ^{
                [[[attribute withValue:value] should] equal:userProfileUpdate];
            });
        });
        context(@"NO", ^{
            BOOL const value = NO;
            it(@"Should create bool value update", ^{
                [[boolValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
                [attribute withValue:value];
            });
            it(@"Should create categorical value update", ^{
                [[factory should] receive:@selector(updateWithUnderlyingUpdate:) withArguments:boolValueUpdate];
                [attribute withValue:value];
            });
            it(@"Should create attribute update", ^{
                [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                                   withArguments:name, theValue(AMAAttributeTypeBool), categoricalValueUpdate];
                [attribute withValue:value];
            });
            it(@"Should return attribute update", ^{
                [[[attribute withValue:value] should] equal:userProfileUpdate];
            });
        });
    });
    context(@"Update with value if undefined", ^{
        beforeEach(^{
            [factory stub:@selector(updateForUndefinedWithUnderlyingUpdate:) andReturn:categoricalValueUpdate];
        });
        context(@"YES", ^{
            BOOL const value = YES;
            it(@"Should create bool value update", ^{
                [[boolValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should create categorical value update", ^{
                [[factory should] receive:@selector(updateForUndefinedWithUnderlyingUpdate:)
                            withArguments:boolValueUpdate];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should create attribute update", ^{
                [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                                   withArguments:name, theValue(AMAAttributeTypeBool), categoricalValueUpdate];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should return attribute update", ^{
                [[[attribute withValueIfUndefined:value] should] equal:userProfileUpdate];
            });
        });
        context(@"NO", ^{
            BOOL const value = NO;
            it(@"Should create bool value update", ^{
                [[boolValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should create categorical value update", ^{
                [[factory should] receive:@selector(updateForUndefinedWithUnderlyingUpdate:)
                            withArguments:boolValueUpdate];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should create attribute update", ^{
                [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                                   withArguments:name, theValue(AMAAttributeTypeBool), categoricalValueUpdate];
                [attribute withValueIfUndefined:value];
            });
            it(@"Should return attribute update", ^{
                [[[attribute withValueIfUndefined:value] should] equal:userProfileUpdate];
            });
        });
    });
    context(@"Update with value reset", ^{
        beforeEach(^{
            [factory stub:@selector(updateWithReset) andReturn:categoricalValueUpdate];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeBool), categoricalValueUpdate];
            [attribute withValueReset];
        });
        it(@"Should return attribute update", ^{
            [[[attribute withValueReset] should] equal:userProfileUpdate];
        });
    });

    it(@"Should conform to AMACustomBoolAttribute", ^{
        [[attribute should] conformToProtocol:@protocol(AMACustomBoolAttribute)];
    });
    it(@"Should conform to AMANotificationsEnabledAttribute", ^{
        [[attribute should] conformToProtocol:@protocol(AMANotificationsEnabledAttribute)];
    });
});

SPEC_END
