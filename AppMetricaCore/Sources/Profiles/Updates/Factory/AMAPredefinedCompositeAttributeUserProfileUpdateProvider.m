
#import "AMAPredefinedCompositeAttributeUserProfileUpdateProvider.h"
#import "AMAUserProfileUpdate.h"
#import "AMAAttributeUpdate.h"

@implementation AMAPredefinedCompositeAttributeUserProfileUpdateProvider

- (AMAAttributeUpdate *)attributeUpdateWithAttributeName:(NSString *)name
                                                    type:(AMAAttributeType)type
                                             valueUpdate:(id<AMAAttributeValueUpdate>)valueUpdate
{
    return [[AMAAttributeUpdate alloc] initWithName:name
                                               type:type
                                             custom:NO
                                        valueUpdate:valueUpdate];
}

- (AMAUserProfileUpdate *)profileUpdateWithAttributeUpdates:(NSArray<AMAAttributeUpdate *> *)attributeUpdates
{
    NSArray *validators = @[
    ];
    return [[AMAUserProfileUpdate alloc] initWithAttributeUpdates:attributeUpdates validators:validators];
}

@end
