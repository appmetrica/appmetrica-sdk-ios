
#import "AMACore.h"
#import "AMAStartupHostProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMADefaultStartupHostsProvider.h"

@interface AMAStartupHostProvider ()

@property (nonatomic, strong) AMAArrayIterator *iterator;

@end

@implementation AMAStartupHostProvider

+ (NSArray *)startupHosts
{
    return [AMAMetricaConfiguration sharedInstance].startup.startupHosts;
}

+ (NSArray *)userStartupHosts
{
    return [AMAMetricaConfiguration sharedInstance].persistent.userStartupHosts;
}

- (id)current
{
    return [self.iterator current];
}

- (id)next
{
    return [self.iterator next];
}

- (void)reset
{
    NSMutableOrderedSet *hosts = [NSMutableOrderedSet new];

    NSArray *array = [[self class] startupHosts];
    if (array != nil) {
        [hosts addObjectsFromArray:array];
    }

    array = [[self class] userStartupHosts];
    if (array != nil) {
        [hosts addObjectsFromArray:array];
    }
    [hosts addObjectsFromArray:[AMADefaultStartupHostsProvider defaultStartupHosts]];

    self.iterator = [[AMAArrayIterator alloc] initWithArray:[hosts array]];
}

@end
