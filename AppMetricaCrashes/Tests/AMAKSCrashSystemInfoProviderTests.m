
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <KSCrash.h>
#import "AMAKSCrashSystemInfoProvider.h"
#import "AMAKSCrashReportDecoder.h"
#import "AMASystemInfo.h"

SPEC_BEGIN(AMAKSCrashSystemInfoProviderTests)

describe(@"AMAKSCrashSystemInfoProvider", ^{

    __block AMAKSCrashReportDecoder *decoder = nil;
    __block AMAKSCrashSystemInfoProvider *provider = nil;
    __block KSCrash *ksCrash = nil;

    beforeEach(^{
        decoder = [AMAKSCrashReportDecoder nullMock];
        provider = [[AMAKSCrashSystemInfoProvider alloc] initWithDecoder:decoder];

        ksCrash = [KSCrash nullMock];
        [KSCrash stub:@selector(sharedInstance) andReturn:ksCrash];
    });

    afterEach(^{
        [KSCrash clearStubs];
    });

    it(@"Should return system info from decoder", ^{
        NSDictionary *systemDict = @{ @"key" : @"value" };
        AMASystemInfo *expectedSystem = [AMASystemInfo nullMock];
        [ksCrash stub:@selector(systemInfo) andReturn:systemDict];
        [decoder stub:@selector(systemInfoForDictionary:) andReturn:expectedSystem withArguments:systemDict];

        AMASystemInfo *result = [provider currentSystemInfo];

        [[result should] equal:expectedSystem];
    });

    it(@"Should pass KSCrash systemInfo dictionary to decoder", ^{
        NSDictionary *systemDict = @{ @"machine" : @"iPhone14,2", @"osVersion" : @"16.0" };
        [ksCrash stub:@selector(systemInfo) andReturn:systemDict];

        [[decoder should] receive:@selector(systemInfoForDictionary:) withArguments:systemDict];

        [provider currentSystemInfo];
    });

    it(@"Should return nil when KSCrash systemInfo is nil", ^{
        [ksCrash stub:@selector(systemInfo) andReturn:nil];
        [decoder stub:@selector(systemInfoForDictionary:) andReturn:nil withArguments:nil];

        AMASystemInfo *result = [provider currentSystemInfo];

        [[result should] beNil];
    });
});

SPEC_END
