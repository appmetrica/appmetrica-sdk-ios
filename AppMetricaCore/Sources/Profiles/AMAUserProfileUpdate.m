
#import "AMAUserProfileUpdate.h"
#import "AMAAttributeUpdateValidating.h"

@implementation AMAUserProfileUpdate

- (instancetype)initWithAttributeUpdates:(NSArray<AMAAttributeUpdate *> *)attributeUpdates
                              validators:(NSArray<id<AMAAttributeUpdateValidating>> *)validators
{
    self = [super init];
    if (self != nil) {
        _attributeUpdates = attributeUpdates;
        _validators = validators;
    }
    return self;
}

@end
