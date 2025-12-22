
#import "AMAFirstPartyDataEmailSha256Attribute.h"
#import "AMAFirstPartyDataSha256Attribute.h"
#import "AMAEmailNormalizer.h"

static NSString *const kAMAFirstPartyEmailSha256Prefix = @"appmetrica_1pd_email_sha256_";
static const NSUInteger kAMAMaxEmailCount = 10;

@implementation AMAFirstPartyDataEmailSha256Attribute

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider
{
    return [super initWithUserProfileUpdateProvider:userProfileUpdateProvider
                                 truncationProvider:truncationProvider
                                         normalizer:[[AMAEmailNormalizer alloc] init]];
}

- (NSString *)attributePrefix
{
    return kAMAFirstPartyEmailSha256Prefix;
}

- (NSUInteger)maxCount
{
    return kAMAMaxEmailCount;
}

- (AMAUserProfileUpdate *)withEmailValues:(NSArray<NSString *> *)values
{
    return [self withValues:values];
}

@end
