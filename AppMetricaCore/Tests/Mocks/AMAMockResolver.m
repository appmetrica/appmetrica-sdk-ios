#import "AMAMockResolver.h"

@implementation AMAMockResolver

@synthesize defaultValue = _defaultValue;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _defaultValue = YES; // default value of AMAPushBaseResolver
    }
    return self;
}

- (void)updateWithValue:(BOOL)value
{
    [self.updateExpectation fulfill];
    self.lastValue = value;
}

@end
