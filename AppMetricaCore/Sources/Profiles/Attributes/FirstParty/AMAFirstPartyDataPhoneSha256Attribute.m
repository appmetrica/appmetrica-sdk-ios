
#import "AMAFirstPartyDataPhoneSha256Attribute.h"
#import "AMAFirstPartyDataSha256Attribute.h"
#import "AMAPhoneNormalizer.h"

static NSString *const kAMAFirstPartyPhoneSha256Prefix = @"appmetrica_1pd_phone_sha256_";
static const NSUInteger kAMAMaxPhoneCount = 10;

@implementation AMAFirstPartyDataPhoneSha256Attribute

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider
{
    return [super initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                 truncationProvider:truncationProvider
                                         normalizer:[[AMAPhoneNormalizer alloc] init]];
}

- (NSString *)attributePrefix
{
    return kAMAFirstPartyPhoneSha256Prefix;
}

- (NSUInteger)maxCount
{
    return kAMAMaxPhoneCount;
}

- (AMAUserProfileUpdate *)withPhoneValues:(NSArray<NSString *> *)values
{
    return [self withValues:values];
}

@end
