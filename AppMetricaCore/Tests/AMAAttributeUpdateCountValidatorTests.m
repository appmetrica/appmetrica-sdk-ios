
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAAttributeUpdateCountValidator.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileModel.h"
#import "AMAUserProfileLogger.h"
#import "AMAAttributeKey.h"

SPEC_BEGIN(AMAAttributeUpdateCountValidatorTests)

describe(@"AMAAttributeUpdateCountValidator", ^{

    NSUInteger const countLimit = 2;
    NSString *const name = @"ATTRIBUTE_NAME";
    AMAAttributeType const type = AMAAttributeTypeNumber;

    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAUserProfileModel *__block model = nil;
    AMAAttributeUpdateCountValidator *__block validator = nil;

    beforeEach(^{
        [AMAUserProfileLogger stub:@selector(logTooManyCustomAttributesWithAttributeName:)];
        attributeUpdate = [AMAAttributeUpdate nullMock];
        [attributeUpdate stub:@selector(name) andReturn:name];
        [attributeUpdate stub:@selector(type) andReturn:theValue(type)];
        model = [[AMAUserProfileModel alloc] init];
        model.attributes = [NSMutableDictionary dictionary];
        validator = [[AMAAttributeUpdateCountValidator alloc] initWithCountLimit:countLimit];
    });
    
    it(@"Should use valid arguments in default initializer", ^{
        validator = [AMAAttributeUpdateCountValidator alloc];
        [[validator should] receive:@selector(initWithCountLimit:) withArguments:theValue(100)];
        id some __unused = [validator init];
    });
    context(@"No attributes", ^{
        context(@"Custom", ^{
            beforeEach(^{
                [attributeUpdate stub:@selector(custom) andReturn:theValue(YES)];
            });
            it(@"Should return YES", ^{
                [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
            });
            it(@"Should not log", ^{
                [[AMAUserProfileLogger shouldNot] receive:@selector(logTooManyCustomAttributesWithAttributeName:)];
                [validator validateUpdate:attributeUpdate model:model];
            });
        });
        context(@"Not custom", ^{
            it(@"Should return YES", ^{
                [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
            });
            it(@"Should not log", ^{
                [[AMAUserProfileLogger shouldNot] receive:@selector(logTooManyCustomAttributesWithAttributeName:)];
                [validator validateUpdate:attributeUpdate model:model];
            });
        });
    });
    context(@"Full attributes", ^{
        beforeEach(^{
            model.customAttributeKeysCount = countLimit;
        });
        context(@"Existing", ^{
            beforeEach(^{
                model.attributes[[[AMAAttributeKey alloc] initWithName:name type:type]] = (id)[NSObject new];
            });
            context(@"Custom", ^{
                beforeEach(^{
                    [attributeUpdate stub:@selector(custom) andReturn:theValue(YES)];
                });
                it(@"Should return YES", ^{
                    [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
                });
                it(@"Should not log", ^{
                    [[AMAUserProfileLogger shouldNot] receive:@selector(logTooManyCustomAttributesWithAttributeName:)];
                    [validator validateUpdate:attributeUpdate model:model];
                });
            });
            context(@"Not custom", ^{
                it(@"Should return YES", ^{
                    [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
                });
                it(@"Should not log", ^{
                    [[AMAUserProfileLogger shouldNot] receive:@selector(logTooManyCustomAttributesWithAttributeName:)];
                    [validator validateUpdate:attributeUpdate model:model];
                });
            });
        });
        context(@"New", ^{
            context(@"Custom", ^{
                beforeEach(^{
                    [attributeUpdate stub:@selector(custom) andReturn:theValue(YES)];
                });
                it(@"Should return NO", ^{
                    [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beNo];
                });
                it(@"Should log", ^{
                    [[AMAUserProfileLogger should] receive:@selector(logTooManyCustomAttributesWithAttributeName:)
                                             withArguments:name];
                    [validator validateUpdate:attributeUpdate model:model];
                });
            });
            context(@"Not custom", ^{
                it(@"Should return YES", ^{
                    [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
                });
                it(@"Should not log", ^{
                    [[AMAUserProfileLogger shouldNot] receive:@selector(logTooManyCustomAttributesWithAttributeName:)];
                    [validator validateUpdate:attributeUpdate model:model];
                });
            });
        });
    });

    it(@"Should conform to AMAAttributeUpdateValidating", ^{
        [[validator should] conformToProtocol:@protocol(AMAAttributeUpdateValidating)];
    });
});

SPEC_END
