
#import <Kiwi/Kiwi.h>
#import "AMAProfileAttribute.h"
#import "AMAStringAttribute.h"
#import "AMANumberAttribute.h"
#import "AMACounterAttribute.h"
#import "AMABoolAttribute.h"
#import "AMADateAttribute.h"
#import "AMAGenderAttribute.h"
#import "AMAAttributeNameProvider.h"
#import "AMAPredefinedAttributeUserProfileUpdateProvider.h"
#import "AMACustomAttributeUserProfileUpdateProvider.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAStringAttributeTruncatorFactory.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAProfileAttributeTests)

describe(@"AMAProfileAttribute", ^{

    NSString *const attributeName = @"ATTRIBUTE_NAME";

    AMAPredefinedAttributeUserProfileUpdateProvider *__block predefinedUpdateProvider = nil;
    AMACustomAttributeUserProfileUpdateProvider *__block customUpdateProvider = nil;
    AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
    AMAStringAttribute *__block stringAttribute = nil;
    AMABoolAttribute *__block boolAttribute = nil;

    beforeEach(^{
        predefinedUpdateProvider = [AMAPredefinedAttributeUserProfileUpdateProvider stubbedNullMockForDefaultInit];
        customUpdateProvider = [AMACustomAttributeUserProfileUpdateProvider stubbedNullMockForDefaultInit];
        truncationProvider = [AMAStringAttributeTruncationProvider nullMock];
        stringAttribute =
            [AMAStringAttribute stubbedNullMockForInit:@selector(initWithName:userProfileUpdateProvider:truncationProvider:)];
        boolAttribute = [AMABoolAttribute stubbedNullMockForInit:@selector(initWithName:userProfileUpdateProvider:)];
    });

    context(@"Name", ^{
        beforeEach(^{
            [AMAAttributeNameProvider stub:@selector(name) andReturn:attributeName];
            [AMAStringAttributeTruncatorFactory stub:@selector(nameTruncationProvider) andReturn:truncationProvider];
        });
        it(@"Should create string attribute", ^{
            [[stringAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:truncationProvider:)
                                withArguments:attributeName, predefinedUpdateProvider, truncationProvider];
            [AMAProfileAttribute name];
        });
        it(@"Should return created attribute", ^{
            [[(NSObject *)[AMAProfileAttribute name] should] equal:stringAttribute];
        });
    });
    context(@"Gender", ^{
        AMAGenderAttribute *__block genderAttribute = nil;
        beforeEach(^{
            genderAttribute = [AMAGenderAttribute stubbedNullMockForInit:@selector(initWithStringAttribute:)];
            [AMAAttributeNameProvider stub:@selector(gender) andReturn:attributeName];
            [AMAStringAttributeTruncatorFactory stub:@selector(genderTruncationProvider) andReturn:truncationProvider];
        });
        it(@"Should create string attribute", ^{
            [[stringAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:truncationProvider:)
                                withArguments:attributeName, predefinedUpdateProvider, truncationProvider];
            [AMAProfileAttribute gender];
        });
        it(@"Should create gender attribute", ^{
            [[genderAttribute should] receive:@selector(initWithStringAttribute:) withArguments:stringAttribute];
            [AMAProfileAttribute gender];
        });
        it(@"Should return created attribute", ^{
            [[(NSObject *)[AMAProfileAttribute gender] should] equal:genderAttribute];
        });
    });
    context(@"Birth date", ^{
        AMADateAttribute *__block dateAttribute = nil;
        beforeEach(^{
            dateAttribute = [AMADateAttribute stubbedNullMockForInit:@selector(initWithStringAttribute:)];
            [AMAAttributeNameProvider stub:@selector(birthDate) andReturn:attributeName];
            [AMAStringAttributeTruncatorFactory stub:@selector(birthDateTruncationProvider)
                                           andReturn:truncationProvider];
        });
        it(@"Should create string attribute", ^{
            [[stringAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:truncationProvider:)
                                withArguments:attributeName, predefinedUpdateProvider, truncationProvider];
            [AMAProfileAttribute birthDate];
        });
        it(@"Should create gender attribute", ^{
            [[dateAttribute should] receive:@selector(initWithStringAttribute:) withArguments:stringAttribute];
            [AMAProfileAttribute birthDate];
        });
        it(@"Should return created attribute", ^{
            [[(NSObject *)[AMAProfileAttribute birthDate] should] equal:dateAttribute];
        });
    });
    context(@"Notifications enabled", ^{
        beforeEach(^{
            [AMAAttributeNameProvider stub:@selector(notificationsEnabled) andReturn:attributeName];
        });
        it(@"Should create bool attribute", ^{
            [[boolAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:)
                              withArguments:attributeName, predefinedUpdateProvider];
            [AMAProfileAttribute notificationsEnabled];
        });
        it(@"Should return created attribute", ^{
            [[(NSObject *)[AMAProfileAttribute notificationsEnabled] should] equal:boolAttribute];
        });
    });
    context(@"Custom", ^{
        NSString *const customName = @"CUSTOM_NAME";
        context(@"String", ^{
            beforeEach(^{
                [AMAAttributeNameProvider stub:@selector(customStringWithName:) andReturn:attributeName];
                [AMAStringAttributeTruncatorFactory stub:@selector(customStringTruncationProvider)
                                               andReturn:truncationProvider];
            });
            it(@"Should request attribute name", ^{
                [[AMAAttributeNameProvider should] receive:@selector(customStringWithName:) withArguments:customName];
                [AMAProfileAttribute customString:customName];
            });
            it(@"Should create attribute", ^{
                [[stringAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:truncationProvider:)
                                    withArguments:attributeName, customUpdateProvider, truncationProvider];
                [AMAProfileAttribute customString:customName];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute customString:customName] should] equal:stringAttribute];
            });
        });
        context(@"Number", ^{
            AMANumberAttribute *__block numberAttribute = nil;
            beforeEach(^{
                numberAttribute =
                    [AMANumberAttribute stubbedNullMockForInit:@selector(initWithName:userProfileUpdateProvider:)];
                [AMAAttributeNameProvider stub:@selector(customNumberWithName:) andReturn:attributeName];
            });
            it(@"Should request attribute name", ^{
                [[AMAAttributeNameProvider should] receive:@selector(customNumberWithName:) withArguments:customName];
                [AMAProfileAttribute customNumber:customName];
            });
            it(@"Should create attribute", ^{
                [[numberAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:)
                                    withArguments:attributeName, customUpdateProvider];
                [AMAProfileAttribute customNumber:customName];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute customNumber:customName] should] equal:numberAttribute];
            });
        });
        context(@"Counter", ^{
            AMACounterAttribute *__block counterAttribute = nil;
            beforeEach(^{
                counterAttribute =
                    [AMACounterAttribute stubbedNullMockForInit:@selector(initWithName:userProfileUpdateProvider:)];
                [AMAAttributeNameProvider stub:@selector(customCounterWithName:) andReturn:attributeName];
            });
            it(@"Should request attribute name", ^{
                [[AMAAttributeNameProvider should] receive:@selector(customCounterWithName:) withArguments:customName];
                [AMAProfileAttribute customCounter:customName];
            });
            it(@"Should create attribute", ^{
                [[counterAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:)
                                     withArguments:attributeName, customUpdateProvider];
                [AMAProfileAttribute customCounter:customName];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute customCounter:customName] should] equal:counterAttribute];
            });
        });
        context(@"Bool", ^{
            beforeEach(^{
                [AMAAttributeNameProvider stub:@selector(customBoolWithName:) andReturn:attributeName];
            });
            it(@"Should request attribute name", ^{
                [[AMAAttributeNameProvider should] receive:@selector(customBoolWithName:) withArguments:customName];
                [AMAProfileAttribute customBool:customName];
            });
            it(@"Should create attribute", ^{
                [[boolAttribute should] receive:@selector(initWithName:userProfileUpdateProvider:)
                                  withArguments:attributeName, customUpdateProvider];
                [AMAProfileAttribute customBool:customName];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute customBool:customName] should] equal:boolAttribute];
            });
        });
    });

});

SPEC_END
