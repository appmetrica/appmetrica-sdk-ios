
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMACategoricalAttributeValueUpdateFactory.h"
#import "AMAUndefinedAwareAttributeValueUpdate.h"
#import "AMAResetAwareAttributeValueUpdate.h"

SPEC_BEGIN(AMACategoricalAttributeValueUpdateFactoryTests)

describe(@"AMACategoricalAttributeValueUpdateFactory", ^{

    NSObject<AMAAttributeValueUpdate> *__block underlyingUpdate;
    AMAResetAwareAttributeValueUpdate *__block resetUpdate;
    AMAUndefinedAwareAttributeValueUpdate *__block permanentUpdate;
    AMACategoricalAttributeValueUpdateFactory *__block factory;

    beforeEach(^{
        underlyingUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
        resetUpdate =
            [AMAResetAwareAttributeValueUpdate stubbedNullMockForInit:@selector(initWithIsReset:underlyingValueUpdate:)];
        permanentUpdate =
            [AMAUndefinedAwareAttributeValueUpdate stubbedNullMockForInit:@selector(initWithIsUndefined:underlyingValueUpdate:)];
        factory = [[AMACategoricalAttributeValueUpdateFactory alloc] init];
    });

    context(@"Value update", ^{
        it(@"Should create valid reset update", ^{
            [[resetUpdate should] receive:@selector(initWithIsReset:underlyingValueUpdate:)
                            withArguments:theValue(NO), underlyingUpdate];
            [factory updateWithUnderlyingUpdate:underlyingUpdate];
        });
        it(@"Should create valid undefined update", ^{
            [[permanentUpdate should] receive:@selector(initWithIsUndefined:underlyingValueUpdate:)
                                withArguments:theValue(NO), resetUpdate];
            [factory updateWithUnderlyingUpdate:underlyingUpdate];
        });
        it(@"Should return valid update", ^{
            [[(NSObject *)[factory updateWithUnderlyingUpdate:underlyingUpdate] should] equal:permanentUpdate];
        });
    });
    context(@"Permanent value update", ^{
        it(@"Should create valid reset update", ^{
            [[resetUpdate should] receive:@selector(initWithIsReset:underlyingValueUpdate:)
                            withArguments:theValue(NO), underlyingUpdate];
            [factory updateForUndefinedWithUnderlyingUpdate:underlyingUpdate];
        });
        it(@"Should create valid undefined update", ^{
            [[permanentUpdate should] receive:@selector(initWithIsUndefined:underlyingValueUpdate:)
                                withArguments:theValue(YES), resetUpdate];
            [factory updateForUndefinedWithUnderlyingUpdate:underlyingUpdate];
        });
        it(@"Should return valid update", ^{
            [[(NSObject *) [factory updateForUndefinedWithUnderlyingUpdate:underlyingUpdate] should] equal:permanentUpdate];
        });
    });
    context(@"Reset", ^{
        it(@"Should create valid reset update", ^{
            [[resetUpdate should] receive:@selector(initWithIsReset:underlyingValueUpdate:)
                            withArguments:theValue(YES), nil];
            [factory updateWithReset];
        });
        it(@"Should create valid undefined update", ^{
            [[permanentUpdate should] receive:@selector(initWithIsUndefined:underlyingValueUpdate:)
                                withArguments:theValue(NO), resetUpdate];
            [factory updateWithReset];
        });
        it(@"Should return valid update", ^{
            [[(NSObject *)[factory updateWithReset] should] equal:permanentUpdate];
        });
    });

});

SPEC_END
