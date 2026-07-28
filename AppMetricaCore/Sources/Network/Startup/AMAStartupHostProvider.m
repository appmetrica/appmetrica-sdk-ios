
#import "AMACore.h"
#import "AMAStartupHostProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
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

+ (NSArray *)libraryAdapterCustomHosts
{
    return [AMAMetricaConfiguration sharedInstance].persistent.libraryAdapterCustomHosts;
}

+ (NSArray *)additionalStartupHosts
{
    return [[AMAMetricaConfiguration sharedInstance].inMemory additionalStartupHosts];
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
    if (array.count > 0) {
        [hosts addObjectsFromArray:array];
    }

    NSArray *userHosts = [[self class] userStartupHosts];
    NSArray *resourceHosts = [AMADefaultStartupHostsProvider resourceStartupHosts];
    if (userHosts.count > 0 || resourceHosts.count > 0) {
        [hosts addObjectsFromArray:userHosts ?: @[]];
        [hosts addObjectsFromArray:resourceHosts ?: @[]];
        self.iterator = [[AMAArrayIterator alloc] initWithArray:[hosts array]];
        return;
    }

    NSArray *libraryAdapterHosts = [[self class] libraryAdapterCustomHosts];
    if (libraryAdapterHosts.count > 0) {
        [hosts addObjectsFromArray:libraryAdapterHosts];
        self.iterator = [[AMAArrayIterator alloc] initWithArray:[hosts array]];
        return;
    }

    NSArray *additionalHosts = [[self class] additionalStartupHosts];
    [hosts addObjectsFromArray:
        [AMADefaultStartupHostsProvider predefinedStartupHostsWithAdditionalHosts:additionalHosts]
    ];

    self.iterator = [[AMAArrayIterator alloc] initWithArray:[hosts array]];
}

@end
