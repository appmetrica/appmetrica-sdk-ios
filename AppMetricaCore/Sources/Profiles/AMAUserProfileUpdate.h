
#import "AMAProfileAttribute.h"

@class AMAAttributeUpdate;
@protocol AMAAttributeUpdateValidating;

@interface AMAUserProfileUpdate ()

@property (nonatomic, copy, readonly) NSArray<AMAAttributeUpdate *> *attributeUpdates;
@property (nonatomic, copy, readonly) NSArray<id<AMAAttributeUpdateValidating>> *validators;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithAttributeUpdates:(NSArray<AMAAttributeUpdate *> *)attributeUpdates
                              validators:(NSArray<id<AMAAttributeUpdateValidating>> *)validators;

@end
