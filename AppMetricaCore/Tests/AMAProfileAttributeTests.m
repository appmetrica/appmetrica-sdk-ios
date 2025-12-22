
#import <AppMetricaKiwi/AppMetricaKiwi.h>
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
#import "AMAFirstPartyDataEmailSha256Attribute.h"
#import "AMAFirstPartyDataPhoneSha256Attribute.h"
#import "AMAFirstPartyDataTelegramLoginSha256Attribute.h"
#import "AMAPredefinedCompositeAttributeUserProfileUpdateProvider.h"
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
    afterEach(^{
        [AMAPredefinedAttributeUserProfileUpdateProvider clearStubs];
        [AMACustomAttributeUserProfileUpdateProvider clearStubs];
        [AMAStringAttribute clearStubs];
        [AMABoolAttribute clearStubs];
    });

    context(@"Name", ^{
        beforeEach(^{
            [AMAAttributeNameProvider stub:@selector(name) andReturn:attributeName];
            [AMAStringAttributeTruncatorFactory stub:@selector(nameTruncationProvider) andReturn:truncationProvider];
        });
        afterEach(^{
            [AMAAttributeNameProvider clearStubs];
            [AMAStringAttributeTruncatorFactory clearStubs];
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
        afterEach(^{
            [AMAGenderAttribute clearStubs];
            [AMAAttributeNameProvider clearStubs];
            [AMAStringAttributeTruncatorFactory clearStubs];
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
        afterEach(^{
            [AMADateAttribute clearStubs];
            [AMAAttributeNameProvider clearStubs];
            [AMAStringAttributeTruncatorFactory clearStubs];
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
        afterEach(^{
            [AMAAttributeNameProvider clearStubs];
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
            afterEach(^{
                [AMAAttributeNameProvider clearStubs];
                [AMAStringAttributeTruncatorFactory clearStubs];
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
            afterEach(^{
                [AMANumberAttribute clearStubs];
                [AMAAttributeNameProvider clearStubs];
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
            afterEach(^{
                [AMACounterAttribute clearStubs];
                [AMAAttributeNameProvider clearStubs];
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
            afterEach(^{
                [AMAAttributeNameProvider clearStubs];
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

    context(@"First Party Data SHA256 Attributes", ^{
        AMAPredefinedCompositeAttributeUserProfileUpdateProvider *__block compositeUpdateProvider = nil;
        AMAStringAttributeTruncationProvider *__block truncationProvider = nil;
        AMAFirstPartyDataEmailSha256Attribute *__block emailAttribute = nil;
        AMAFirstPartyDataPhoneSha256Attribute *__block phoneAttribute = nil;
        AMAFirstPartyDataTelegramLoginSha256Attribute *__block telegramAttribute = nil;

        beforeEach(^{
            compositeUpdateProvider = [AMAPredefinedCompositeAttributeUserProfileUpdateProvider stubbedNullMockForDefaultInit];
            truncationProvider = [AMAStringAttributeTruncationProvider nullMock];
            emailAttribute = [AMAFirstPartyDataEmailSha256Attribute stubbedNullMockForInit:@selector(initWithUserProfileUpdateProvider:truncationProvider:)];
            phoneAttribute = [AMAFirstPartyDataPhoneSha256Attribute stubbedNullMockForInit:@selector(initWithUserProfileUpdateProvider:truncationProvider:)];
            telegramAttribute = [AMAFirstPartyDataTelegramLoginSha256Attribute stubbedNullMockForInit:@selector(initWithUserProfileUpdateProvider:truncationProvider:)];
        });
        afterEach(^{
            [AMAPredefinedCompositeAttributeUserProfileUpdateProvider clearStubs];
            [AMAFirstPartyDataEmailSha256Attribute clearStubs];
            [AMAFirstPartyDataPhoneSha256Attribute clearStubs];
            [AMAFirstPartyDataTelegramLoginSha256Attribute clearStubs];
        });
        
        context(@"Email hash", ^{
            beforeEach(^{
                [AMAStringAttributeTruncatorFactory stub:@selector(customStringTruncationProvider) andReturn:truncationProvider];
            });
            afterEach(^{
                [AMAStringAttributeTruncatorFactory clearStubs];
            });
            
            it(@"Should create email hash attribute", ^{
                [[emailAttribute should] receive:@selector(initWithUserProfileUpdateProvider:truncationProvider:)
                                   withArguments:compositeUpdateProvider, truncationProvider];
                [AMAProfileAttribute emailHash];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute emailHash] should] equal:emailAttribute];
            });
        });
        
        context(@"Phone hash", ^{
            beforeEach(^{
                [AMAStringAttributeTruncatorFactory stub:@selector(customStringTruncationProvider) andReturn:truncationProvider];
            });
            afterEach(^{
                [AMAStringAttributeTruncatorFactory clearStubs];
            });
            
            it(@"Should create phone hash attribute", ^{
                [[phoneAttribute should] receive:@selector(initWithUserProfileUpdateProvider:truncationProvider:)
                                   withArguments:compositeUpdateProvider, truncationProvider];
                [AMAProfileAttribute phoneHash];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute phoneHash] should] equal:phoneAttribute];
            });
        });
        
        context(@"Telegram login hash", ^{
            beforeEach(^{
                [AMAStringAttributeTruncatorFactory stub:@selector(customStringTruncationProvider) andReturn:truncationProvider];
            });
            afterEach(^{
                [AMAStringAttributeTruncatorFactory clearStubs];
            });
            
            it(@"Should create telegram login hash attribute", ^{
                [[telegramAttribute should] receive:@selector(initWithUserProfileUpdateProvider:truncationProvider:)
                                      withArguments:compositeUpdateProvider, truncationProvider];
                [AMAProfileAttribute telegramLoginHash];
            });
            it(@"Should return created attribute", ^{
                [[(NSObject *)[AMAProfileAttribute telegramLoginHash] should] equal:telegramAttribute];
            });
        });
    });

});

SPEC_END
