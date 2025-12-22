
#import <Foundation/Foundation.h>
#import "AMACompositeUserProfileUpdateProviding.h"
#import "AMAAttributeType.h"

@class AMAAttributeUpdate;
@class AMAUserProfileUpdate;
@protocol AMAAttributeValueUpdate;

@protocol AMACompositeUserProfileUpdateProviding <NSObject>

- (AMAAttributeUpdate *)attributeUpdateWithAttributeName:(NSString *)name
                                                    type:(AMAAttributeType)type
                                             valueUpdate:(id<AMAAttributeValueUpdate>)valueUpdate;

- (AMAUserProfileUpdate *)profileUpdateWithAttributeUpdates:(NSArray<AMAAttributeUpdate *> *)attributeUpdates;

@end
