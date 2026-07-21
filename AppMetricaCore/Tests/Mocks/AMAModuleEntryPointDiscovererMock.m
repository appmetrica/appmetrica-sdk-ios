#import "AMAModuleEntryPointDiscovererMock.h"

@interface AMAModuleEntryPointDiscovererMock ()
@property (atomic, readwrite) NSUInteger discoverCallCount;
@end

@implementation AMAModuleEntryPointDiscovererMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _entryPoints = @[];
    }
    return self;
}

- (NSArray<id<AMAModuleEntryPoint>> *)discoverEntryPoints
{
    @synchronized (self) {
        self.discoverCallCount += 1;
    }
    if (self.discoveryBlock != nil) {
        return self.discoveryBlock();
    }
    return self.entryPoints;
}

@end
