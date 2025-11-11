
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStartupHostProvider.h"
#import "AMADefaultStartupHostsProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"

@interface AMAStartupHostProvider ()

- (NSArray *)startupHosts;
- (NSArray *)userStartupHosts;

@end

SPEC_BEGIN(AMAStartupHostProviderTests)

describe(@"AMAStartupHostProvider", ^{
    NSString *const defaultHost = @"https://startup.mobile.yandex.net";
    
    NSArray *const predefinedHosts = @[defaultHost];
    
    AMAStartupHostProvider * __block hostProvider = nil;
    NSArray * __block startupHosts = @[@"1", @"2", @"3"];
    NSArray * __block userHosts = @[@"4", @"5"];
    
    NSArray * (^allItemsFromProvider)(AMAStartupHostProvider *) = ^NSArray *(AMAStartupHostProvider * hostProvider) {
        NSMutableArray *items = [NSMutableArray new];
        
        while (hostProvider.current != nil) {
            [items addObject: hostProvider.current];
            [hostProvider next];
        }
        
        return items;
    };
    
    beforeEach(^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:@[]];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:@[]];
    });
    
    it(@"Should contain default startup host if no hosts provided by user or startup responce", ^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:nil];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:nil];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        NSArray *actualValue = allItemsFromProvider(hostProvider);
        
        [[actualValue should] equal:@[defaultHost]];
    });
    
    it(@"Should contain startup hosts and default host", ^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:startupHosts];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:nil];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        NSArray *actualValue = allItemsFromProvider(hostProvider);
        NSArray *expected = [startupHosts arrayByAddingObjectsFromArray:predefinedHosts];
        
        [[actualValue should] equal:expected];
    });
    
    it(@"Should contain startup hosts, user hosts and default host", ^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:startupHosts];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:userHosts];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        NSArray *actualValue = allItemsFromProvider(hostProvider);
        
        NSArray *expected = [startupHosts arrayByAddingObjectsFromArray:userHosts];
        expected = [expected arrayByAddingObjectsFromArray:predefinedHosts];
        
        [[actualValue should] equal:expected];
    });
    
    it(@"Should contain startup hosts and default host only once", ^{
        NSArray * __block startupHosts = @[@"1", @"2", @"3", defaultHost, @"7", defaultHost];
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:startupHosts];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:nil];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        NSArray *actualValue = allItemsFromProvider(hostProvider);
        NSArray *expected = @[@"1", @"2", @"3", defaultHost, @"7"];
        
        [[actualValue should] equal:expected];
    });
    
    it(@"Should use additional hosts with predefined on reset", ^{
        NSArray *additionalHosts = @[@"host_1", @"host_2"];
        
        [AMADefaultStartupHostsProvider stub:@selector(startupHostsWithAdditionalHosts:)
                                   andReturn:[predefinedHosts arrayByAddingObjectsFromArray:additionalHosts]
                               withArguments:additionalHosts];
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(additionalStartupHosts)
                                                      andReturn:additionalHosts];
        
        [[AMADefaultStartupHostsProvider should] receive:@selector(startupHostsWithAdditionalHosts:)
                                           withArguments:additionalHosts];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        
        [[hostProvider.current should] equal:predefinedHosts[0]];
        [[hostProvider.next should] equal:additionalHosts[0]];
        [[hostProvider.next should] equal:additionalHosts[1]];
    });
});

SPEC_END
