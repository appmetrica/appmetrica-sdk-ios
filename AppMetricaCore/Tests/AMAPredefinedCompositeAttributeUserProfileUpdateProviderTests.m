
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAPredefinedCompositeAttributeUserProfileUpdateProvider.h"
#import "AMAAttributeUpdate.h"
#import "AMAAttributeValueUpdate.h"
#import "AMAUserProfileUpdate.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAPredefinedCompositeAttributeUserProfileUpdateProviderTests)

describe(@"AMAPredefinedCompositeAttributeUserProfileUpdateProvider", ^{

    NSString *const name = @"ATTRIBUTE_NAME";
    AMAAttributeType const type = AMAAttributeTypeString;

    NSObject<AMAAttributeValueUpdate> *__block valueUpdate = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAPredefinedCompositeAttributeUserProfileUpdateProvider *__block provider = nil;

    beforeEach(^{
        valueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
        userProfileUpdate = [AMAUserProfileUpdate stubbedNullMockForInit:@selector(initWithAttributeUpdates:validators:)];
        attributeUpdate = [AMAAttributeUpdate stubbedNullMockForInit:@selector(initWithName:type:custom:valueUpdate:)];
        provider = [[AMAPredefinedCompositeAttributeUserProfileUpdateProvider alloc] init];
    });
    afterEach(^{
        [AMAUserProfileUpdate clearStubs];
        [AMAAttributeUpdate clearStubs];
    });

    context(@"attributeUpdateWithAttributeName:type:valueUpdate:", ^{
        it(@"Should create attribute update with custom NO", ^{
            [[attributeUpdate should] receive:@selector(initWithName:type:custom:valueUpdate:)
                                withArguments:name, theValue(type), theValue(NO), valueUpdate];
            [provider attributeUpdateWithAttributeName:name type:type valueUpdate:valueUpdate];
        });

        it(@"Should return attribute update", ^{
            [[[provider attributeUpdateWithAttributeName:name type:type valueUpdate:valueUpdate] should] equal:attributeUpdate];
        });
    });

    context(@"profileUpdateWithAttributeUpdates:", ^{
        NSArray<AMAAttributeUpdate *> *__block attributeUpdates = nil;

        beforeEach(^{
            AMAAttributeUpdate *update1 = [AMAAttributeUpdate nullMock];
            AMAAttributeUpdate *update2 = [AMAAttributeUpdate nullMock];
            attributeUpdates = @[update1, update2];
        });

        it(@"Should create user profile update with empty validators", ^{
            [[userProfileUpdate should] receive:@selector(initWithAttributeUpdates:validators:)
                                  withArguments:attributeUpdates, @[]];
            [provider profileUpdateWithAttributeUpdates:attributeUpdates];
        });

        it(@"Should return user profile update", ^{
            [[[provider profileUpdateWithAttributeUpdates:attributeUpdates] should] equal:userProfileUpdate];
        });
    });

    it(@"Should conform to AMACompositeUserProfileUpdateProviding", ^{
        [[provider should] conformToProtocol:@protocol(AMACompositeUserProfileUpdateProviding)];
    });
});

SPEC_END
