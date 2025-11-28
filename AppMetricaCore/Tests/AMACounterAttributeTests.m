
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACounterAttribute.h"
#import "AMACounterAttributeValueUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileUpdateProviding.h"

SPEC_BEGIN(AMACounterAttributeTests)

describe(@"AMACustomCounterAttribute", ^{

    NSString *const name = @"ATTRIBUTE NAME";

    NSObject<AMAUserProfileUpdateProviding> *__block updateProvider = nil;
    AMACounterAttributeValueUpdate *__block valueUpdate = nil;
    AMAUserProfileUpdate *__block userProfileUpdate = nil;

    AMACounterAttribute *__block attribute = nil;

    beforeEach(^{
        updateProvider = [KWMock nullMockForProtocol:@protocol(AMAUserProfileUpdateProviding)];
        userProfileUpdate = [AMAUserProfileUpdate nullMock];
        [updateProvider stub:@selector(updateWithAttributeName:type:valueUpdate:) andReturn:userProfileUpdate];
        valueUpdate = [AMACounterAttributeValueUpdate stubbedNullMockForInit:@selector(initWithDeltaValue:)];
        attribute = [[AMACounterAttribute alloc] initWithName:name userProfileUpdateProvider:updateProvider];
    });
    afterEach(^{
        [AMACounterAttributeValueUpdate clearStubs];
    });

    context(@"Update with delta", ^{
        double const delta = 23;
        it(@"Should create valid value update", ^{
            [[valueUpdate should] receive:@selector(initWithDeltaValue:) withArguments:theValue(delta)];
            [attribute withDelta:delta];
        });
        it(@"Should create valid attribute update", ^{
            [[updateProvider should] receive:@selector(updateWithAttributeName:type:valueUpdate:)
                               withArguments:name, theValue(AMAAttributeTypeCounter), valueUpdate];
            [attribute withDelta:delta];
        });
        it(@"Should return valid update", ^{
            [[[attribute withDelta:delta] should] equal:userProfileUpdate];
        });
    });

    it(@"Should conform to AMACustomCounterAttribute", ^{
        [[attribute should] conformToProtocol:@protocol(AMACustomCounterAttribute)];
    });
});

SPEC_END
