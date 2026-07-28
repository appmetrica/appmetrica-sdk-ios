
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAStartupHostProvider.h"
#import "AMADefaultStartupHostsProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"

@interface AMAStartupHostProvider ()

- (NSArray *)startupHosts;
- (NSArray *)userStartupHosts;
- (NSArray *)libraryAdapterCustomHosts;

@end

SPEC_BEGIN(AMAStartupHostProviderTests)

describe(@"AMAStartupHostProvider", ^{
    NSString *const defaultHost = @"https://startup.mobile.yandex.net";
    
    NSArray *const predefinedHosts = @[defaultHost];
    
    AMAStartupHostProvider * __block hostProvider = nil;
    NSArray * __block startupHosts = @[@"1", @"2", @"3"];
    NSArray * __block userHosts = @[@"4", @"5"];
    NSArray * __block libraryAdapterHosts = @[@"6", @"7"];
    NSArray * __block resourceHosts = @[@"8", @"9"];
    
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
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:@[]];
        [AMADefaultStartupHostsProvider stub:@selector(resourceStartupHosts) andReturn:@[]];
    });
    afterEach(^{
        [AMAStartupHostProvider clearStubs];
        [AMADefaultStartupHostsProvider clearStubs];
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
    
    it(@"Should contain startup and user hosts without default host", ^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:startupHosts];
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:userHosts];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        NSArray *actualValue = allItemsFromProvider(hostProvider);
        
        NSArray *expected = [startupHosts arrayByAddingObjectsFromArray:userHosts];
        
        [[actualValue should] equal:expected];
    });

    it(@"Should use library adapter hosts without default host", ^{
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:libraryAdapterHosts];

        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];

        [[allItemsFromProvider(hostProvider) should] equal:libraryAdapterHosts];
    });

    it(@"Should prepend startup hosts to library adapter hosts", ^{
        [AMAStartupHostProvider stub:@selector(startupHosts) andReturn:startupHosts];
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:libraryAdapterHosts];

        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];

        NSArray *expected = [startupHosts arrayByAddingObjectsFromArray:libraryAdapterHosts];
        [[allItemsFromProvider(hostProvider) should] equal:expected];
    });

    it(@"Should prefer user hosts over library adapter hosts", ^{
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:userHosts];
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:libraryAdapterHosts];

        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];

        [[allItemsFromProvider(hostProvider) should] equal:userHosts];
    });

    it(@"Should prefer resource hosts over library adapter hosts", ^{
        [AMADefaultStartupHostsProvider stub:@selector(resourceStartupHosts) andReturn:resourceHosts];
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:libraryAdapterHosts];

        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];

        [[allItemsFromProvider(hostProvider) should] equal:resourceHosts];
    });

    it(@"Should combine user and resource hosts before ignoring library adapter hosts", ^{
        [AMAStartupHostProvider stub:@selector(userStartupHosts) andReturn:userHosts];
        [AMADefaultStartupHostsProvider stub:@selector(resourceStartupHosts) andReturn:resourceHosts];
        [AMAStartupHostProvider stub:@selector(libraryAdapterCustomHosts) andReturn:libraryAdapterHosts];

        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];

        NSArray *expected = [userHosts arrayByAddingObjectsFromArray:resourceHosts];
        [[allItemsFromProvider(hostProvider) should] equal:expected];
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
        
        [AMADefaultStartupHostsProvider stub:@selector(predefinedStartupHostsWithAdditionalHosts:)
                                   andReturn:[predefinedHosts arrayByAddingObjectsFromArray:additionalHosts]
                               withArguments:additionalHosts];
        [[AMAMetricaConfiguration sharedInstance].inMemory stub:@selector(additionalStartupHosts)
                                                      andReturn:additionalHosts];
        
        [[AMADefaultStartupHostsProvider should] receive:@selector(predefinedStartupHostsWithAdditionalHosts:)
                                           withArguments:additionalHosts];
        
        hostProvider = [AMAStartupHostProvider new];
        [hostProvider reset];
        
        [[hostProvider.current should] equal:predefinedHosts[0]];
        [[hostProvider.next should] equal:additionalHosts[0]];
        [[hostProvider.next should] equal:additionalHosts[1]];
        
        [[AMAMetricaConfiguration sharedInstance].inMemory clearStubs];
        [AMADefaultStartupHostsProvider clearStubs];
    });
});

SPEC_END
