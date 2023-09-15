
#import <Kiwi/Kiwi.h>
#import "AMAPredefinedAttributeUserProfileUpdateProvider.h"
#import "AMAAttributeUpdate.h"
#import "AMAAttributeValueUpdate.h"
#import "AMAUserProfileUpdate.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAPredefinedAttributeUserProfileUpdateProviderTests)

describe(@"AMAPredefinedAttributeUserProfileUpdateProvider", ^{

    NSString *const name = @"ATTRIBUTE_NAME";
    AMAAttributeType const type = AMAAttributeTypeCounter;

    NSObject<AMAAttributeValueUpdate> *__block valueUpdate = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAPredefinedAttributeUserProfileUpdateProvider *__block provider = nil;

    beforeEach(^{
        valueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
        userProfileUpdate = [AMAUserProfileUpdate stubbedNullMockForInit:@selector(initWithAttributeUpdate:validators:)];
        attributeUpdate = [AMAAttributeUpdate stubbedNullMockForInit:@selector(initWithName:type:custom:valueUpdate:)];
        provider = [[AMAPredefinedAttributeUserProfileUpdateProvider alloc] init];
    });

    it(@"Should create attribute update", ^{
        [[attributeUpdate should] receive:@selector(initWithName:type:custom:valueUpdate:)
                            withArguments:name, theValue(type), theValue(NO), valueUpdate];
        [provider updateWithAttributeName:name type:type valueUpdate:valueUpdate];
    });
    it(@"Should create user profile update", ^{
        [[userProfileUpdate should] receive:@selector(initWithAttributeUpdate:validators:)
                              withArguments:attributeUpdate, @[]];
        [provider updateWithAttributeName:name type:type valueUpdate:valueUpdate];
    });
    it(@"Should return update", ^{
        [[[provider updateWithAttributeName:name type:type valueUpdate:valueUpdate] should] equal:userProfileUpdate];
    });

    it(@"Should conform to AMAUserProfileUpdateProviding", ^{
        [[provider should] conformToProtocol:@protocol(AMAUserProfileUpdateProviding)];
    });
});

SPEC_END
