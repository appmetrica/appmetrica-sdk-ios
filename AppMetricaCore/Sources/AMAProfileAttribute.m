
#import "AMAProfileAttribute.h"
#import "AMAStringAttribute.h"
#import "AMANumberAttribute.h"
#import "AMACounterAttribute.h"
#import "AMABoolAttribute.h"
#import "AMAGenderAttribute.h"
#import "AMADateAttribute.h"
#import "AMAAttributeNameProvider.h"
#import "AMAPredefinedAttributeUserProfileUpdateProvider.h"
#import "AMACustomAttributeUserProfileUpdateProvider.h"
#import "AMAStringAttributeTruncatorFactory.h"
#import "AMAFirstPartyDataPhoneSha256Attribute.h"
#import "AMAFirstPartyDataEmailSha256Attribute.h"
#import "AMAFirstPartyDataTelegramLoginSha256Attribute.h"
#import "AMAPredefinedCompositeAttributeUserProfileUpdateProvider.h"

@implementation AMAProfileAttribute

+ (id<AMAUserProfileUpdateProviding>)predefinedAttributeUserProfileUpdateProvider
{
    return [[AMAPredefinedAttributeUserProfileUpdateProvider alloc] init];
}

+ (id<AMAUserProfileUpdateProviding>)customAttributeUserProfileUpdateProvider
{
    return [[AMACustomAttributeUserProfileUpdateProvider alloc] init];
}

+ (id<AMACompositeUserProfileUpdateProviding>)predefinedCompositeAttributeUserProfileUpdateProvider
{
    return [[AMAPredefinedCompositeAttributeUserProfileUpdateProvider alloc] init];
}

+ (id<AMANameAttribute>)name
{
    return [[AMAStringAttribute alloc] initWithName:[AMAAttributeNameProvider name]
                          userProfileUpdateProvider:[self predefinedAttributeUserProfileUpdateProvider]
                                 truncationProvider:[AMAStringAttributeTruncatorFactory nameTruncationProvider]];
}

+ (id<AMAGenderAttribute>)gender
{
    AMAStringAttribute *stringAttribute =
        [[AMAStringAttribute alloc] initWithName:[AMAAttributeNameProvider gender]
                       userProfileUpdateProvider:[self predefinedAttributeUserProfileUpdateProvider]
                              truncationProvider:[AMAStringAttributeTruncatorFactory genderTruncationProvider]];
    return [[AMAGenderAttribute alloc] initWithStringAttribute:stringAttribute];
}

+ (id<AMABirthDateAttribute>)birthDate
{
    AMAStringAttribute *stringAttribute =
        [[AMAStringAttribute alloc] initWithName:[AMAAttributeNameProvider birthDate]
                       userProfileUpdateProvider:[self predefinedAttributeUserProfileUpdateProvider]
                              truncationProvider:[AMAStringAttributeTruncatorFactory birthDateTruncationProvider]];
    return [[AMADateAttribute alloc] initWithStringAttribute:stringAttribute];
}

+ (id<AMANotificationsEnabledAttribute>)notificationsEnabled
{
    return [[AMABoolAttribute alloc] initWithName:[AMAAttributeNameProvider notificationsEnabled]
                        userProfileUpdateProvider:[self predefinedAttributeUserProfileUpdateProvider]];
}


+ (id<AMAFirstPartyDataPhoneSha256Attribute>)phoneHash
{
    return [[AMAFirstPartyDataPhoneSha256Attribute alloc] initWithUserProfileUpdateProvider:[self predefinedCompositeAttributeUserProfileUpdateProvider]
                                                                         truncationProvider:[AMAStringAttributeTruncatorFactory customStringTruncationProvider]];
}

+ (id<AMAFirstPartyDataEmailSha256Attribute>)emailHash
{
    return [[AMAFirstPartyDataEmailSha256Attribute alloc] initWithUserProfileUpdateProvider:[self predefinedCompositeAttributeUserProfileUpdateProvider]
                                                                         truncationProvider:[AMAStringAttributeTruncatorFactory customStringTruncationProvider]];
}

+ (id<AMAFirstPartyDataTelegramLoginSha256Attribute>)telegramLoginHash
{
    return [[AMAFirstPartyDataTelegramLoginSha256Attribute alloc] initWithUserProfileUpdateProvider:[self predefinedCompositeAttributeUserProfileUpdateProvider]
                                                                                 truncationProvider:[AMAStringAttributeTruncatorFactory customStringTruncationProvider]];
}

+ (id<AMACustomStringAttribute>)customString:(NSString *)name
{
    return [[AMAStringAttribute alloc] initWithName:[AMAAttributeNameProvider customStringWithName:name]
                          userProfileUpdateProvider:[self customAttributeUserProfileUpdateProvider]
                                 truncationProvider:[AMAStringAttributeTruncatorFactory customStringTruncationProvider]];
}

+ (id<AMACustomNumberAttribute>)customNumber:(NSString *)name
{
    return [[AMANumberAttribute alloc] initWithName:[AMAAttributeNameProvider customNumberWithName:name]
                          userProfileUpdateProvider:[self customAttributeUserProfileUpdateProvider]];
}

+ (id<AMACustomCounterAttribute>)customCounter:(NSString *)name
{
    return [[AMACounterAttribute alloc] initWithName:[AMAAttributeNameProvider customCounterWithName:name]
                           userProfileUpdateProvider:[self customAttributeUserProfileUpdateProvider]];
}

+ (id<AMACustomBoolAttribute>)customBool:(NSString *)name
{
    return [[AMABoolAttribute alloc] initWithName:[AMAAttributeNameProvider customBoolWithName:name]
                        userProfileUpdateProvider:[self customAttributeUserProfileUpdateProvider]];
}

@end
