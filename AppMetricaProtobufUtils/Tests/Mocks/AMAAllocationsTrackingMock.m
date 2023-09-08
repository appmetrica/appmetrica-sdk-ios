
#import "AMAAllocationsTrackingMock.h"

@implementation AMAAllocationsTrackingMock

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        self.allocations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void *)allocateSize:(size_t)size
{
    NSMutableData *data = [NSMutableData dataWithLength:size];
    self.allocations[@(size)] = data;
    return data.mutableBytes;
}

@end
