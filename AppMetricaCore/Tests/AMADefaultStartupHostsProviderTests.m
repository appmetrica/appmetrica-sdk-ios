#import <Kiwi/Kiwi.h>
#import "AMADefaultStartupHostsProvider.h"

SPEC_BEGIN(AMADefaultStartupHostsProviderTests)

describe(@"AMADefaultStartupHostsProvider", ^{
    NSString *const customHost = @"https://appmetrica.io";
    NSString *const defaultHost = @"https://startup.mobile.yandex.net";

    NSString *const kAMADefaultStartupHostsKey = @"AMASDKStartupHosts";

    it(@"Should return custom hosts if bundle belongs to main app", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.app"]];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
        [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[customHost]];
    });
    
    it(@"Should return custom hosts if bundle belongs to app extension", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"file://Users/Library/Developer/main.appex"]];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
        [NSBundle stub:@selector(bundleWithURL:) andReturn:bundle];
        [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[customHost]];
    });

    it(@"Should return custom hosts if found loaded bundle with value", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.bundle"]];
        [bundle stub:@selector(isLoaded) andReturn:theValue(YES)];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
        [NSBundle stub:@selector(allBundles) andReturn:@[bundle]];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle nullMock]];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[customHost]];
    });

    it(@"Should return predefined hosts if found not loaded bundle with value", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.bundle"]];
        [bundle stub:@selector(isLoaded) andReturn:theValue(NO)];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
        [NSBundle stub:@selector(allBundles) andReturn:@[bundle]];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle nullMock]];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[defaultHost]];
    });

    it(@"Should return predefined hosts if the value is not an NSArray", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:@"main.app"];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: customHost}];
        [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        [NSBundle stub:@selector(allBundles) andReturn:@[bundle]];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[defaultHost]];
    });

    it(@"Should return predefined hosts if the value in array is not NSString", ^{
        NSBundle *bundle = [NSBundle nullMock];
        [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.app"]];
        [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[@1]}];
        [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[defaultHost]];
    });

    it(@"Should return predefined hosts if bundle not found", ^{
        [NSBundle stub:@selector(allBundles) andReturn:@[]];
        [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle nullMock]];
        NSArray *hosts = [AMADefaultStartupHostsProvider defaultStartupHosts];

        [[hosts should] equal:@[defaultHost]];
    });
});

SPEC_END
