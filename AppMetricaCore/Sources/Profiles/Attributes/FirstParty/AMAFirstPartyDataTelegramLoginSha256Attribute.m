
#import "AMAFirstPartyDataTelegramLoginSha256Attribute.h"
#import "AMAFirstPartyDataSha256Attribute.h"
#import "AMATelegramLoginNormalizer.h"

static NSString *const kAMAFirstPartyTelegramLoginSha256Prefix = @"appmetrica_1pd_telegram_sha256_";
static const NSUInteger kAMAMaxTelegramLoginCount = 10;

@implementation AMAFirstPartyDataTelegramLoginSha256Attribute

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider
{
    return [super initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                 truncationProvider:truncationProvider
                                         normalizer:[[AMATelegramLoginNormalizer alloc] init]];
}

- (NSString *)attributePrefix
{
    return kAMAFirstPartyTelegramLoginSha256Prefix;
}

- (NSUInteger)maxCount
{
    return kAMAMaxTelegramLoginCount;
}

- (AMAUserProfileUpdate *)withTelegramLoginValues:(NSArray<NSString *> *)values
{
    return [self withValues:values];
}

@end
