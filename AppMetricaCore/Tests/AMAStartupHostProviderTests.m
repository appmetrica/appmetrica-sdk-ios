
#import <Kiwi/Kiwi.h>
#import "AMAStartupHostProvider.h"
#import "AMADefaultStartupHostsProvider.h"

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
        [AMADefaultStartupHostsProvider stub:@selector(defaultStartupHosts) andReturn:predefinedHosts];
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
    
    it(@"Should call DefaultStartupHostsProvider on reset", ^{
        NSArray *hosts = @[@"host_1", @"host_2"];
        [AMADefaultStartupHostsProvider stub:@selector(defaultStartupHosts) andReturn:hosts];
        
        [[AMADefaultStartupHostsProvider should] receive:@selector(defaultStartupHosts)];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        
        [[theValue(hostProvider.current) should] equal:theValue(hosts[0])];
        [[theValue(hostProvider.next) should] equal:theValue(hosts[1])];
    });
});

SPEC_END
