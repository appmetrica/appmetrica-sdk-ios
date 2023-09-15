
#import <Kiwi/Kiwi.h>
#import "AMANumberAttribute.h"
#import "AMACategoricalAttributeValueUpdateFactory.h"
#import "AMANumberAttributeValueUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileUpdateProviding.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMANumberAttributeTests)

describe(@"AMANumberAttribute", ^{

    NSString *const name = @"ATTRIBUTE_NAME";
    double const value = 42;

    AMANumberAttributeValueUpdate *__block numberValueUpdate = nil;
    AMACategoricalAttributeValueUpdateFactory *__block factory = nil;
    NSObject<AMAUserProfileUpdateProviding> *__block updateProvider = nil;
    NSObject<AMAAttributeValueUpdate> *__block categoricalValueUpdate = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMANumberAttribute *__block attribute = nil;

    beforeEach(^{
        numberValueUpdate = [AMANumberAttributeValueUpdate stubbedNullMockForInit:@selector(initWithValue:)];
        factory = [AMACategoricalAttributeValueUpdateFactory nullMock];
        updateProvider = [KWMock nullMockForProtocol:@protocol(AMAUserProfileUpdateProviding)];
        userProfileUpdate = [AMAUserProfileUpdate nullMock];
        [updateProvider stub:@selector(updateWithAttributeName:type:valueUpdate:) andReturn:userProfileUpdate];
        categoricalValueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
        attribute = [[AMANumberAttribute alloc] initWithName:name
                                   userProfileUpdateProvider:updateProvider
                                    categoricalUpdateFactory:factory];
    });

    context(@"Update with value", ^{
        beforeEach(^{
            [factory stub:@selector(updateWithUnderlyingUpdate:) andReturn:categoricalValueUpdate];
        });
        it(@"Should create number value update", ^{
            [[numberValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
            [attribute withValue:value];
        });
        it(@"Should create categorical value update", ^{
            [[factory should] receive:@selector(updateWithUnderlyingUpdate:) withArguments:numberValueUpdate];
            [attribute withValue:value];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeNumber), categoricalValueUpdate];
            [attribute withValue:value];
        });
        it(@"Should return attribute update", ^{
            [[[attribute withValue:value] should] equal:userProfileUpdate];
        });
    });
    context(@"Update with value if undefined", ^{
        beforeEach(^{
            [factory stub:@selector(updateForUndefinedWithUnderlyingUpdate:) andReturn:categoricalValueUpdate];
        });
        it(@"Should create number value update", ^{
            [[numberValueUpdate should] receive:@selector(initWithValue:) withArguments:theValue(value)];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should create categorical value update", ^{
            [[factory should] receive:@selector(updateForUndefinedWithUnderlyingUpdate:)
                        withArguments:numberValueUpdate];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeNumber), categoricalValueUpdate];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should return attribute update", ^{
            [[[attribute withValueIfUndefined:value] should] equal:userProfileUpdate];
        });
    });
    context(@"Update with value reset", ^{
        beforeEach(^{
            [factory stub:@selector(updateWithReset) andReturn:categoricalValueUpdate];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeNumber), categoricalValueUpdate];
            [attribute withValueReset];
        });
        it(@"Should return attribute update", ^{
            [[[attribute withValueReset] should] equal:userProfileUpdate];
        });
    });

    it(@"Should conform to AMACustomNumberAttribute", ^{
        [[attribute should] conformToProtocol:@protocol(AMACustomNumberAttribute)];
    });
});

SPEC_END
