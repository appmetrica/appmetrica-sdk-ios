#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMADefaultStartupHostsProvider.h"

SPEC_BEGIN(AMADefaultStartupHostsProviderTests)

describe(@"AMADefaultStartupHostsProvider", ^{
    
    NSString *const kAMADefaultStartupHostsKey = @"AMASDKStartupHosts";
    
    NSString *const customHost = @"https://appmetrica.io";
    NSString *const defaultHost = @"https://startup.mobile.yandex.net";
    NSArray *const additionalStartupHosts = @[@"https://startup.host.com", @"https://startup.host.net"];
    NSArray *const predefinedHosts = [@[defaultHost] arrayByAddingObjectsFromArray:additionalStartupHosts];
    NSBundle *__block bundle = nil;
    
    NSArray *(^extractHosts)() = ^{
        return [AMADefaultStartupHostsProvider startupHostsWithAdditionalHosts:additionalStartupHosts];
    };
    
    beforeEach(^{
        bundle = [NSBundle nullMock];
    });
    
    context(@"App bundle", ^{
        beforeEach(^{
            [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.app"]];
            [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
            [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        });
        it(@"Should return custom hosts if bundle belongs to main app", ^{
            [[extractHosts() should] equal:@[customHost]];
        });
    });
    context(@"App extension bundle", ^{
        beforeEach(^{
            [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"file://Users/Library/Developer/main.appex"]];
            [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
            [NSBundle stub:@selector(bundleWithURL:) andReturn:bundle];
            [NSBundle stub:@selector(mainBundle) andReturn:bundle];
        });
        it(@"Should return custom hosts if bundle belongs to app extension", ^{
            [[extractHosts() should] equal:@[customHost]];
        });
    });
    context(@"Loaded bundle", ^{
        beforeEach(^{
            [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.bundle"]];
            [bundle stub:@selector(isLoaded) andReturn:theValue(YES)];
            [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[customHost]}];
            [NSBundle stub:@selector(allBundles) andReturn:@[bundle]];
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle nullMock]];
        });
        it(@"Should return custom hosts if found loaded bundle with value", ^{
            [[extractHosts() should] equal:@[customHost]];
        });
        it(@"Should return custom hosts if found not loaded bundle with value", ^{
            [bundle stub:@selector(isLoaded) andReturn:theValue(NO)];
            
            [[extractHosts() should] equal:predefinedHosts];
        });
    });
    context(@"Invalid type", ^{
        it(@"Should return predefined hosts if the value is not an NSArray", ^{
            [bundle stub:@selector(bundleURL) andReturn:@"main.app"];
            [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: customHost}];
            [NSBundle stub:@selector(mainBundle) andReturn:bundle];
            [NSBundle stub:@selector(allBundles) andReturn:@[bundle]];
            
            [[extractHosts() should] equal:predefinedHosts];
        });
        
        it(@"Should return predefined hosts if the value in array is not NSString", ^{
            NSBundle *bundle = [NSBundle nullMock];
            [bundle stub:@selector(bundleURL) andReturn:[NSURL fileURLWithPath:@"main.app"]];
            [bundle stub:@selector(infoDictionary) andReturn:@{kAMADefaultStartupHostsKey: @[@1]}];
            [NSBundle stub:@selector(mainBundle) andReturn:bundle];
            
            [[extractHosts() should] equal:predefinedHosts];
        });
    });
    context(@"No bundle", ^{
        it(@"Should return predefined hosts if bundle not found", ^{
            [NSBundle stub:@selector(allBundles) andReturn:@[]];
            [NSBundle stub:@selector(mainBundle) andReturn:[NSBundle nullMock]];
            
            [[extractHosts() should] equal:predefinedHosts];
        });
    });
});

SPEC_END
