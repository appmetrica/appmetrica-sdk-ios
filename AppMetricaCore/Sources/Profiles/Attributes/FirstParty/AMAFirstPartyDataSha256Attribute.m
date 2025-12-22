
#import "AMAFirstPartyDataSha256Attribute.h"
#import "AMAStringAttributeValueUpdate.h"
#import "AMAAttributeUpdate.h"
#import "AMAStringAttributeTruncationProvider.h"
#import "AMAAttributeValueNormalizer.h"
#import "AMAUserProfileUpdate.h"
#import "AMAPredefinedCompositeAttributeUserProfileUpdateProvider.h"
#import <AppMetricaEncodingUtils/AppMetricaEncodingUtils.h>

@implementation AMAFirstPartyDataSha256Attribute

- (instancetype)initWithUserProfileUpdateProvider:(id<AMACompositeUserProfileUpdateProviding>)userProfileUpdateProvider
                               truncationProvider:(AMAStringAttributeTruncationProvider *)truncationProvider
                                       normalizer:(id<AMAAttributeValueNormalizer>)normalizer
{
    self = [super init];
    if (self != nil) {
        _userProfileUpdateProvider = userProfileUpdateProvider;
        _truncationProvider = truncationProvider;
        _normalizer = normalizer;
    }
    return self;
}

- (NSString *)attributePrefix
{
    return @"";
}

- (NSUInteger)maxCount
{
    return 0;
}

- (AMAUserProfileUpdate *)withValues:(NSArray<NSString *> *)values
{
    NSMutableOrderedSet<NSString *> *hashes = [NSMutableOrderedSet orderedSet];

    for (NSUInteger i = 0; i < values.count; i++) {
        NSString *value = values[i];
        NSString *normalizedValue = [self normalizedValue:value];

        if (normalizedValue != nil) {
            NSString *hash = [AMAHashUtility sha256HashForString:normalizedValue];

            if (hash != nil && hash.length > 0) {
                [hashes addObject:hash];
            }
        }
    }

    return [self withHashes:hashes.array];
}

- (AMAUserProfileUpdate *)withHashes:(NSArray<NSString *> *)hashes
{
    NSMutableArray<AMAAttributeUpdate *> *attributeUpdates = [NSMutableArray array];
    NSUInteger count = MIN(hashes.count, [self maxCount]);

    for (NSUInteger i = 0; i < count; i++) {
        NSString *hash = hashes[i];
        NSString *attributeName = [NSString stringWithFormat:@"%@%lu",
                                   [self attributePrefix],
                                   (unsigned long)i];
        AMAAttributeUpdate *update = [self createAttributeUpdateWithAttributeName:attributeName
                                                                            value:hash];
        [attributeUpdates addObject:update];
    }

    return [self.userProfileUpdateProvider profileUpdateWithAttributeUpdates:attributeUpdates];
}

- (AMAAttributeUpdate *)createAttributeUpdateWithAttributeName:(NSString *)name
                                                         value:(NSString *)value
{
    id<AMAStringTruncating> truncator = [self.truncationProvider truncatorWithAttributeName:name];
    id<AMAAttributeValueUpdate> valueUpdate = [[AMAStringAttributeValueUpdate alloc] initWithValue:value
                                                                                          truncator:truncator];
    return [self.userProfileUpdateProvider attributeUpdateWithAttributeName:name
                                                                       type:AMAAttributeTypeString
                                                                valueUpdate:valueUpdate];
}

- (NSString *)normalizedValue:(NSString *)value
{
    return [[[self.normalizer normalizeValue:value]
             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
            lowercaseString];
}

@end
