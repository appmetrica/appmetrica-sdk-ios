
#import <Foundation/Foundation.h>

@class AMAUserProfileUpdate;
@class AMAAttributeUpdate;
@class AMAStringAttributeTruncationProvider;
@protocol AMACompositeUserProfileUpdateProviding;
@protocol AMAAttributeValueNormalizer;

@interface AMAFirstPartyDataSha256Attribute : NSObject

@property (nonatomic, strong, readonly) id<AMACompositeUserProfileUpdateProviding> userProfileUpdateProvider;
@property (nonatomic, strong, readonly) AMAStringAttributeTruncationProvider *truncationProvider;
@property (nonatomic, strong, readonly) id<AMAAttributeValueNormalizer> normalizer;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider
                                       normalizer:(id<AMAAttributeValueNormalizer>)normalizer;

- (NSString *)attributePrefix;
- (NSUInteger)maxCount;

- (AMAUserProfileUpdate *)withValues:(NSArray<NSString *> *)values;

@end
