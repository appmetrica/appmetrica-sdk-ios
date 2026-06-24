#import "AMAAdRevenueSourceContainerMock.h"

@implementation AMAAdRevenueSourceContainerMock

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.nativeSupportedSources = @[ @"yandex" ];
    }
    return self;
}

- (void)addNativeSupportedSource:(NSString*)source
{
    if ([self.nativeSupportedSources containsObject:source]) {
        return;
    }
    NSMutableArray *newSources = [self.nativeSupportedSources mutableCopy];
    [newSources addObject:source];
    self.nativeSupportedSources = newSources;
}

@end
