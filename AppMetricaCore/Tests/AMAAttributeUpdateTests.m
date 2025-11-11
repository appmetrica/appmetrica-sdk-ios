
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAttributeUpdate.h"
#import "AMAAttributeValueUpdate.h"
#import "AMAAttributeKey.h"
#import "AMAAttributeValue.h"
#import "AMAUserProfileModel.h"

SPEC_BEGIN(AMAAttributeUpdateTests)

describe(@"AMAAttributeUpdate", ^{

    NSString *const name = @"NAME";
    AMAAttributeType const type = AMAAttributeTypeCounter;

    AMAUserProfileModel *__block model = nil;
    AMAAttributeKey *__block key = nil;
    AMAAttributeValue *__block value = nil;
    NSObject<AMAAttributeValueUpdate> *__block valueUpdate = nil;
    AMAAttributeUpdate *__block update = nil;

    beforeEach(^{
        key = [[AMAAttributeKey alloc] initWithName:name type:type];
        model = [[AMAUserProfileModel alloc] init];
        valueUpdate = [KWMock nullMockForProtocol:@protocol(AMAAttributeValueUpdate)];
    });
    
    context(@"Custom", ^{
        beforeEach(^{
            update = [[AMAAttributeUpdate alloc] initWithName:name type:type custom:YES valueUpdate:valueUpdate];
        });
        it(@"Should store name", ^{
            [[update.name should] equal:name];
        });
        it(@"Should store custom flag", ^{
            [[theValue(update.custom) should] beYes];
        });
        context(@"New attribute", ^{
            beforeEach(^{
                value = [AMAAttributeValue stubbedNullMockForDefaultInit];
            });
            it(@"Should apply update", ^{
                [[valueUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToModel:model];
            });
            it(@"Should store attribute", ^{
                [update applyToModel:model];
                [[model.attributes[key] should] equal:value];
            });
            it(@"Should increment custom attributes count", ^{
                [update applyToModel:model];
                [[theValue(model.customAttributeKeysCount) should] equal:theValue(1)];
            });
        });
        context(@"Existing attribute", ^{
            beforeEach(^{
                value = [AMAAttributeValue nullMock];
                model.attributes = [NSMutableDictionary dictionary];
                model.attributes[key] = value;
            });
            it(@"Should apply update", ^{
                [[valueUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToModel:model];
            });
            it(@"Should store attribute", ^{
                [update applyToModel:model];
                [[model.attributes[key] should] equal:value];
            });
            it(@"Should not increment custom attributes count", ^{
                [update applyToModel:model];
                [[theValue(model.customAttributeKeysCount) should] beZero];
            });
        });
    });
    context(@"Not custom", ^{
        beforeEach(^{
            update = [[AMAAttributeUpdate alloc] initWithName:name type:type custom:NO valueUpdate:valueUpdate];
        });
        it(@"Should store name", ^{
            [[update.name should] equal:name];
        });
        it(@"Should store custom flag", ^{
            [[theValue(update.custom) should] beNo];
        });
        context(@"New attribute", ^{
            beforeEach(^{
                value = [AMAAttributeValue stubbedNullMockForDefaultInit];
            });
            it(@"Should apply update", ^{
                [[valueUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToModel:model];
            });
            it(@"Should store attribute", ^{
                [update applyToModel:model];
                [[model.attributes[key] should] equal:value];
            });
            it(@"Should not increment custom attributes count", ^{
                [update applyToModel:model];
                [[theValue(model.customAttributeKeysCount) should] beZero];
            });
        });
        context(@"Existing attribute", ^{
            beforeEach(^{
                value = [AMAAttributeValue nullMock];
                model.attributes = [NSMutableDictionary dictionary];
                model.attributes[key] = value;
            });
            it(@"Should apply update", ^{
                [[valueUpdate should] receive:@selector(applyToValue:) withArguments:value];
                [update applyToModel:model];
            });
            it(@"Should store attribute", ^{
                [update applyToModel:model];
                [[model.attributes[key] should] equal:value];
            });
            it(@"Should not increment custom attributes count", ^{
                [update applyToModel:model];
                [[theValue(model.customAttributeKeysCount) should] beZero];
            });
        });
    });

});

SPEC_END
