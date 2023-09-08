
#import "AMAKSCrash.h"
@import KSCrash_Recording;

#import <Kiwi/Kiwi.h>

SPEC_BEGIN(AMAKSCrashTests)

describe(@"AMAKSCrash", ^{

    beforeAll(^{
        kscm_system_getAPI()->setEnabled(true);
    });

    afterAll(^{
        kscm_system_getAPI()->setEnabled(false);
    });

    it(@"Should contain valid keys in system info dict", ^{
        NSSet *expectedKeys = [NSSet setWithArray:@[
            @"appID",
            @"appStartTime",
            @"binaryCPUSubType",
            @"binaryCPUType",
            @"bootTime",
            @"buildType",
            @"bundleID",
            @"bundleName",
            @"bundleShortVersion",
            @"bundleVersion",
            @"cpuArchitecture",
            @"cpuSubType",
            @"cpuType",
            @"deviceAppHash",
            @"executableName",
            @"executablePath",
            @"freeMemory",
            @"isJailbroken",
            @"kernelVersion",
            @"machine",
            @"memorySize",
            @"model",
            @"osVersion",
            @"parentProcessID",
            @"processID",
            @"processName",
            @"storageSize",
            @"systemName",
            @"systemVersion",
            @"timezone",
            @"usableMemory",
        ]];

        NSSet *actualKeys = [NSSet setWithArray:[[AMAKSCrash sharedInstance] systemInfo].allKeys];
        
        [[actualKeys should] equal:expectedKeys];
    });
});

SPEC_END
