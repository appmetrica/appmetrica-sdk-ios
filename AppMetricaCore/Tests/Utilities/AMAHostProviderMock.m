
#import "AMAHostProviderMock.h"

@interface AMAHostProviderMock ()

@property (nonatomic, copy) NSArray *items;
@property (nonatomic, strong) AMAArrayIterator *iterator;
@property (nonatomic, assign) NSUInteger numberOfTimesHitNext;
@property (nonatomic, assign) NSUInteger numberOfTimesHitReset;

@end

@implementation AMAHostProviderMock

- (instancetype)initWithItems:(NSArray *)items
{
    self = [super init];
    if (self != nil) {
        [self resetWithItems:items];
    }

    return self;
}

- (id)next
{
    self.numberOfTimesHitNext ++;
    return [self.iterator next];
}

- (id)current
{
    return [self.iterator current];
}

- (void)resetWithItems:(NSArray *)items
{
    self.items = items;
    self.iterator = [[AMAArrayIterator alloc] initWithArray:items];
}

- (void)reset
{
    self.numberOfTimesHitReset ++;
    [self resetWithItems:self.items];
}

@end
