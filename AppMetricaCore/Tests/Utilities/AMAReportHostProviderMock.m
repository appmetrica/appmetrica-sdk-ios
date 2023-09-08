
#import "AMAReportHostProviderMock.h"
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

@interface AMAReportHostProviderMock ()

@property (nonatomic, copy) NSDictionary *items;
@property (nonatomic, strong) AMAArrayIterator *iterator;
@property (nonatomic, assign) NSUInteger numberOfTimesHitNext;
@property (nonatomic, assign) NSUInteger numberOfTimesHitReset;

@end

@implementation AMAReportHostProviderMock

- (instancetype)initWithItems:(NSDictionary *)items
{
    self = [super init];
    if (self != nil) {
        _items = [items copy];
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

- (void)resetForApiKey:(NSString *)apiKey
{
    self.numberOfTimesHitReset ++;
    self.iterator = [[AMAArrayIterator alloc] initWithArray:self.items[apiKey]];
}

@end
