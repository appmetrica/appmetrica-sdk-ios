
#import <Kiwi/Kiwi.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

SPEC_BEGIN(AMAApplicationStateTests)

describe(@"AMAApplicationState", ^{
    let(appState, ^{ return [[AMAApplicationState alloc] initWithAppVersionName:@"1.1.1"
                                                                  appDebuggable:YES
                                                                     kitVersion:@"4.2.0"
                                                                 kitVersionName:@"testName"
                                                                 kitBuildNumber:420
                                                                   kitBuildType:@"Debug"
                                                                      OSVersion:@"16.0.1"
                                                                     OSAPILevel:16
                                                                         locale:@"en-US"
                                                                       isRooted:NO
                                                                           UUID:@"testUUID"
                                                                       deviceID:@"testID"
                                                                            IFV:@"testIFV"
                                                                            IFA:@"testIFA"
                                                                            LAT:NO
                                                                 appBuildNumber:@"1.1.1"];
    });

    it(@"Should conform to AMADictionaryRepresentation protocol", ^{
        [[appState should] conformToProtocol:@protocol(AMADictionaryRepresentation)];
    });
    
    it(@"Should conform to NSCopying protocol", ^{
        [[appState should] conformToProtocol:@protocol(NSCopying)];
    });
    
    it(@"Should conform to NSMutableCopying protocol", ^{
        [[appState should] conformToProtocol:@protocol(NSMutableCopying)];
    });
    
    it(@"Should compare empty app states", ^{
        [[[AMAApplicationState new] should] equal:[AMAApplicationState new]];
    });

    context(@"When initialized with dictionary", ^{
        NSDictionary *const kAMATestDictionary = @{
            @"app_build_number": @"200",
            @"app_debuggable": @"1",
            @"app_version_name": @"1.0",
            @"deviceid": @"sample-deviceid",
            @"ifa": @"sample-ifa",
            @"ifv": @"sample-ifv",
            @"is_rooted": @"0",
            @"analytics_sdk_build_number": @"100",
            @"analytics_sdk_build_type": @"Release",
            @"analytics_sdk_version": @"2.0",
            @"analytics_sdk_version_name": @"2.0.1",
            @"limit_ad_tracking": @"0",
            @"locale": @"en_US",
            @"os_api_level": @"30",
            @"os_version": @"15.0",
            @"uuid": @"sample-uuid",
        };

        let(appState, ^{ return [AMAApplicationState objectWithDictionaryRepresentation:kAMATestDictionary]; });

        it(@"should properly initialize properties from dictionary", ^{
            [[appState.appVersionName should] equal:kAMATestDictionary[@"app_version_name"]];
            [[theValue(appState.appDebuggable) should] beTrue];
            [[appState.kitVersion should] equal:kAMATestDictionary[@"analytics_sdk_version"]];
            [[appState.kitVersionName should] equal:kAMATestDictionary[@"analytics_sdk_version_name"]];
            [[theValue(appState.kitBuildNumber) should] equal:theValue([kAMATestDictionary[@"analytics_sdk_build_number"] integerValue])];
            [[appState.kitBuildType should] equal:kAMATestDictionary[@"analytics_sdk_build_type"]];
            [[appState.OSVersion should] equal:kAMATestDictionary[@"os_version"]];
            [[theValue(appState.OSAPILevel) should] equal:theValue([kAMATestDictionary[@"os_api_level"] integerValue])];
            [[appState.locale should] equal:kAMATestDictionary[@"locale"]];
            [[theValue(appState.isRooted) should] beFalse];
            [[appState.UUID should] equal:kAMATestDictionary[@"uuid"]];
            [[appState.deviceID should] equal:kAMATestDictionary[@"deviceid"]];
            [[appState.appBuildNumber should] equal:kAMATestDictionary[@"app_build_number"]];
            [[appState.IFV should] equal:kAMATestDictionary[@"ifv"]];
            [[appState.IFA should] equal:kAMATestDictionary[@"ifa"]];
            [[theValue(appState.LAT) should] beFalse];
        });

        it(@"should return the same dictionary representation", ^{
            NSDictionary *resultDictionary = appState.dictionaryRepresentation;
            [[resultDictionary should] equal:kAMATestDictionary];
        });
    });

    context(@"when copying", ^{
        let(copiedAppState, ^{ return appState.copy; });

        it(@"should create an equal copy of the app state", ^{
            [[copiedAppState should] equal:appState];
        });

        it(@"should have separate memory addresses for the copied instance", ^{
            [[theValue(copiedAppState) shouldNot] equal:theValue(appState)];
        });
    });

    context(@"when mutable copying", ^{
        let(mutableCopiedAppState, ^{ return appState.mutableCopy; });

        it(@"should create an equal mutable copy of the app state", ^{
            [[mutableCopiedAppState should] equal:appState];
            [[appState should] equal:mutableCopiedAppState];
        });

        it(@"should have separate memory addresses for the mutable copied instance", ^{
            [[theValue(mutableCopiedAppState) shouldNot] equal:theValue(appState)];
        });
    });

    context(@"when updating app version and app build number", ^{
        NSString *newAppVersion = @"2.0";
        NSString *newAppBuildNumber = @"300";

        let(updatedAppState, ^{
            return [appState copyWithNewAppVersion:newAppVersion appBuildNumber:newAppBuildNumber];
        });
        
        it(@"should create an updated app state with new app version and app build number", ^{
            [[updatedAppState.appVersionName should] equal:newAppVersion];
            [[updatedAppState.appBuildNumber should] equal:newAppBuildNumber];
        });

        it(@"should not affect the original app state", ^{
            [[appState.appVersionName shouldNot] equal:newAppVersion];
            [[appState.appBuildNumber shouldNot] equal:newAppBuildNumber];
        });
    });
    
    context(@"when calculating hash", ^{
        it(@"should have equal hashes for equal properties", ^{
            __auto_type *appState1 = [[AMAMutableApplicationState alloc] init];
            appState1.appVersionName = @"1.0.0";
            appState1.kitVersion = @"1.0.1";
            appState1.locale = @"en-US";
            appState1.UUID = @"12345678-1234-1234-1234-1234567890ab";
            
            __auto_type *appState2 = [[AMAMutableApplicationState alloc] init];
            appState2.appVersionName = @"1.0.0";
            appState2.kitVersion = @"1.0.1";
            appState2.locale = @"en-US";
            appState2.UUID = @"12345678-1234-1234-1234-1234567890ab";
            
            [[theValue(appState1.hash) should] equal:theValue((appState2.hash))];
        });
        
        it(@"should have different hashes for equal properties", ^{
            __auto_type *appState1 = [[AMAMutableApplicationState alloc] init];
            appState1.appVersionName = @"1.0.0";
            appState1.kitVersion = @"1.0.1";
            appState1.locale = @"en-US";
            appState1.UUID = @"12345678-1234-1234-1234-1234567890ab";
            
            __auto_type *appState2 = [[AMAMutableApplicationState alloc] init];
            appState2.appVersionName = @"2.0.0";
            appState2.kitVersion = @"1.0.1";
            appState2.locale = @"en-US";
            appState2.UUID = @"12345678-1234-1234-1234-1234567890ab";
            
            [[theValue(appState1.hash) shouldNot] equal:theValue((appState2.hash))];
        });
    });
});

SPEC_END
