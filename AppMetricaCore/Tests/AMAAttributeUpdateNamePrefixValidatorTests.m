
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAttributeUpdateNamePrefixValidator.h"
#import "AMAUserProfileLogger.h"
#import "AMAAttributeUpdate.h"
#import "AMAUserProfileModel.h"

SPEC_BEGIN(AMAAttributeUpdateNamePrefixValidatorTests)

describe(@"AMAAttributeUpdateNamePrefixValidator", ^{

    NSString *const prefix = @"PREFIX";

    NSString *__block name = nil;
    AMAAttributeUpdate *__block attributeUpdate = nil;
    AMAUserProfileModel *__block model = nil;
    AMAAttributeUpdateNamePrefixValidator *__block validator = nil;

    beforeEach(^{
        [AMAUserProfileLogger stub:@selector(logForbiddenAttributeNamePrefixWithName:forbiddenPrefix:)];
        attributeUpdate = [AMAAttributeUpdate nullMock];
        model = [AMAUserProfileModel nullMock];
        validator = [[AMAAttributeUpdateNamePrefixValidator alloc] initWithForbiddenPrefix:prefix];
    });

    it(@"Should use valid arguments in default initializer", ^{
        validator = [AMAAttributeUpdateNamePrefixValidator alloc];
        [[validator should] receive:@selector(initWithForbiddenPrefix:) withArguments:@"appmetrica"];
        id some __unused = [validator init];
    });
    context(@"Without prefix", ^{
        beforeEach(^{
            name = @"PREFI_NAME";
            [attributeUpdate stub:@selector(name) andReturn:name];
        });
        it(@"Should return YES", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beYes];
        });
        it(@"Should not log", ^{
            [[AMAUserProfileLogger shouldNot] receive:@selector(logForbiddenAttributeNamePrefixWithName:forbiddenPrefix:)];
            [validator validateUpdate:attributeUpdate model:model];
        });
    });
    context(@"With prefix", ^{
        beforeEach(^{
            name = [prefix stringByAppendingString:@"_NAME"];
            [attributeUpdate stub:@selector(name) andReturn:name];
        });
        it(@"Should return NO", ^{
            [[theValue([validator validateUpdate:attributeUpdate model:model]) should] beNo];
        });
        it(@"Should log", ^{
            [[AMAUserProfileLogger should] receive:@selector(logForbiddenAttributeNamePrefixWithName:forbiddenPrefix:)
                                     withArguments:name, prefix];
            [validator validateUpdate:attributeUpdate model:model];
        });
    });

    it(@"Should conform to AMAAttributeUpdateValidating", ^{
        [[validator should] conformToProtocol:@protocol(AMAAttributeUpdateValidating)];
    });
});

SPEC_END
