
#import <Foundation/Foundation.h>
#import "AMAProfileAttribute.h"
#import "AMAFirstPartyDataSha256Attribute.h"

@protocol AMACompositeUserProfileUpdateProviding;
@class AMAStringAttributeTruncationProvider;

NS_ASSUME_NONNULL_BEGIN

@interface AMAFirstPartyDataTelegramLoginSha256Attribute : AMAFirstPartyDataSha256Attribute <AMAFirstPartyDataTelegramLoginSha256Attribute>

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider;

@end

NS_ASSUME_NONNULL_END
