
#import <XCTest/XCTest.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "NSBundle+ApplicationBundle.h"

static NSString *const kAMAAppPath = @"/path/to/appmetrica.app";
static NSString *const kAMAExtPath = @"/path/to/appmetrica.app/Plugins/appmetrica.plugin";
static NSString *const kAMAInvalidPath = @"/path/to/something.bundle";

SPEC_BEGIN(NSBundle_ApplicationBundleTests)

describe(@"NSBundle_ApplicationBundleTests", ^{
    
    NSBundle *__block bundle;
    beforeEach(^{
        bundle = [NSBundle mainBundle];
    });
    afterEach(^{
        [NSBundle clearStubs];
    });
    
    void (^installBundleInit)(NSString*) = ^(NSString *path){
        NSURL *url = [NSURL fileURLWithPath:path];
        [[NSBundle should] receive:@selector(bundleWithURL:) withArguments:url];
    };
    
    it(@"should return app bundle itself", ^{
        [bundle stub:@selector(bundlePath) andReturn:kAMAAppPath];
        installBundleInit(kAMAAppPath);
        
        (void)bundle.applicationBundle;
    });
    
    it(@"should return app bundle from extension", ^{
        [bundle stub:@selector(bundlePath) andReturn:kAMAExtPath];
        installBundleInit(kAMAAppPath);
        
        (void)bundle.applicationBundle;
    });
    
    it(@"should return nil from another bundle", ^{
        [bundle stub:@selector(bundlePath) andReturn:kAMAInvalidPath];
        [[NSBundle shouldNot] receive:@selector(bundleWithURL:)];
        
        [bundle.applicationBundle shouldBeNil];
    });
    
});

SPEC_END
