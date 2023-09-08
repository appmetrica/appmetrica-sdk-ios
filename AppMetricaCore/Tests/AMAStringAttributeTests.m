
#import <Kiwi/Kiwi.h>
#import "AMAStringAttribute.h"
#import "AMACategoricalAttributeValueUpdateFactory.h"
#import "AMAStringAttributeValueUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAUserProfileUpdateProviding.h"
#import "AMAUserProfileUpdate.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAStringAttributeTests)

describe(@"AMAStringAttribute", ^{

    NSString *const name = @"ATTRIBUTE_NAME";
    NSString *const value = @"VALUE";

    AMAStringAttributeValueUpdate *__block stringValueUpdate = nil;
    AMACategoricalAttributeValueUpdateFactory *__block factory = nil;
    NSObject<AMAUserProfileUpdateProviding> *__block updateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    NSObject<AMAAttributeValueUpdate> *__block categoricalValueUpdate = nil;
    NSObject<AMAStringTruncating> *__block truncator = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMAStringAttribute *__block attribute = nil;

    beforeEach(^{
        stringValueUpdate = [AMAStringAttributeValueUpdate stubbedNullMockForInit:@selector(initWithValue:truncator:)];
        factory = [AMACategoricalAttributeValueUpdateFactory nullMock];
        updateProvider = [KWMock nullMockForProtocol:@protocol(AMAUserProfileUpdateProviding)];
        userProfileUpdate = [AMAUserProfileUpdate nullMock];
        [updateProvider stub:@selector(updateWithAttributeName:type:valueUpdate:) andReturn:userProfileUpdate];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];
        truncator = [KWMock nullMockForProtocol:@protocol(AMAStringTruncating)];
        [truncationProvider stub:@selector(truncatorWithAttributeName:) andReturn:truncator];
        categoricalValueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];

        attribute = [[AMAStringAttribute alloc] initWithName:name
                                   userProfileUpdateProvider:updateProvider
                                          truncationProvider:truncationProvider
                                    categoricalUpdateFactory:factory];
    });

    context(@"Update with value", ^{
        beforeEach(^{
            [factory stub:@selector(updateWithUnderlyingUpdate:) andReturn:categoricalValueUpdate];
        });
        it(@"Should request truncator with valid name", ^{
            [[truncationProvider should] receive:@selector(truncatorWithAttributeName:) withArguments:name];
            [attribute withValue:value];
        });
        it(@"Should create string value update", ^{
            [[stringValueUpdate should] receive:@selector(initWithValue:truncator:)
                                  withArguments:value, truncator];
            [attribute withValue:value];
        });
        it(@"Should create categorical value update", ^{
            [[factory should] receive:@selector(updateWithUnderlyingUpdate:) withArguments:stringValueUpdate];
            [attribute withValue:value];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeString), categoricalValueUpdate];
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
        it(@"Should request truncator with valid name", ^{
            [[truncationProvider should] receive:@selector(truncatorWithAttributeName:) withArguments:name];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should create string value update", ^{
            [[stringValueUpdate should] receive:@selector(initWithValue:truncator:)
                                  withArguments:value, truncator];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should create categorical value update", ^{
            [[factory should] receive:@selector(updateForUndefinedWithUnderlyingUpdate:)
                        withArguments:stringValueUpdate];
            [attribute withValueIfUndefined:value];
        });
        it(@"Should create attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeString), categoricalValueUpdate];
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
                               withArguments:name, theValue(AMAAttributeTypeString), categoricalValueUpdate];
            [attribute withValueReset];
        });
        it(@"Should return attribute update", ^{
            [[[attribute withValueReset] should] equal:userProfileUpdate];
        });
    });

});

SPEC_END
