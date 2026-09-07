#import <AppMetricaKiwi/AppMetricaKiwi.h>

#import "AMAAppMetricaCrashesConfiguration.h"

@interface TestConfigSubclass : AMAAppMetricaCrashesConfiguration
@end

@implementation TestConfigSubclass
@end

static void AMAAppMetricaCrashesConfigurationTestsCrashCallback(
    __unused const AMAAppMetricaCrashErrorEnvironmentWriter *writer
)
{
}

static void AMAAppMetricaCrashesConfigurationTestsAnotherCrashCallback(
    __unused const AMAAppMetricaCrashErrorEnvironmentWriter *writer
)
{
}

static NSString *const kAMAValidPreActivationAppVersion = @"26.8.3.701";
static NSString *const kAMAValidPreActivationAppBuildNumber = @"701";

SPEC_BEGIN(AMAAppMetricaCrashesConfigurationTests)

describe(@"AMAAppMetricaCrashesConfiguration", ^{
    
    let(config, ^{ return [[AMAAppMetricaCrashesConfiguration alloc] init]; });
    
    context(@"Default property values", ^{

        it(@"Should not have a custom app version by default", ^{
            [[config.preActivationAppVersion should] beNil];
        });

        it(@"Should not have a custom app build number by default", ^{
            [[config.preActivationAppBuildNumber should] beNil];
        });
        
        it(@"Should have autoCrashTracking enabled by default", ^{
            [[theValue(config.autoCrashTracking) should] beYes];
        });
        
        it(@"Should have probablyUnhandledCrashReporting disabled by default", ^{
            [[theValue(config.probablyUnhandledCrashReporting) should] beNo];
        });
        
        it(@"Should not ignore any signals by default", ^{
            [[config.ignoredCrashSignals should] beNil];
        });
        
        it(@"Should have applicationNotRespondingDetection disabled by default", ^{
            [[theValue(config.applicationNotRespondingDetection) should] beNo];
        });
        
        it(@"Should have a default ANR watchdog interval of 4 seconds", ^{
            [[theValue(config.applicationNotRespondingWatchdogInterval) should] equal:theValue(4.0)];
        });
        
        it(@"Should check for ANR every 0.1 second by default", ^{
            [[theValue(config.applicationNotRespondingPingInterval) should] equal:theValue(0.1)];
        });

        it(@"Should not have crash error environment callback by default", ^{
            [[theValue(config.crashErrorEnvironmentCallback == NULL) should] beYes];
        });
    });
    
    context(@"NSCopying behavior", ^{
        
        it(@"Should produce a correct copy with the same property values", ^{
            config.preActivationAppVersion = kAMAValidPreActivationAppVersion;
            config.preActivationAppBuildNumber = kAMAValidPreActivationAppBuildNumber;
            config.autoCrashTracking = NO;
            config.probablyUnhandledCrashReporting = YES;
            config.ignoredCrashSignals = @[ @SIGABRT, @SIGILL ];
            config.applicationNotRespondingDetection = YES;
            config.applicationNotRespondingWatchdogInterval = 5.0;
            config.applicationNotRespondingPingInterval = 0.2;
            config.crashErrorEnvironmentCallback = AMAAppMetricaCrashesConfigurationTestsCrashCallback;
            
            AMAAppMetricaCrashesConfiguration *configCopy = [config copy];
            
            [[configCopy.preActivationAppVersion should] equal:kAMAValidPreActivationAppVersion];
            [[configCopy.preActivationAppBuildNumber should] equal:kAMAValidPreActivationAppBuildNumber];
            [[theValue(configCopy.autoCrashTracking) should] beNo];
            [[theValue(configCopy.probablyUnhandledCrashReporting) should] beYes];
            [[configCopy.ignoredCrashSignals should] equal:@[ @SIGABRT, @SIGILL ]];
            [[theValue(configCopy.applicationNotRespondingDetection) should] beYes];
            [[theValue(configCopy.applicationNotRespondingWatchdogInterval) should] equal:theValue(5.0)];
            [[theValue(configCopy.applicationNotRespondingPingInterval) should] equal:theValue(0.2)];
            [[theValue(configCopy.crashErrorEnvironmentCallback ==
                       AMAAppMetricaCrashesConfigurationTestsCrashCallback) should] beYes];
        });
    });
    
    context(@"Property mutability", ^{
        
        it(@"Should allow changing property values", ^{
            config.preActivationAppVersion = kAMAValidPreActivationAppVersion;
            [[config.preActivationAppVersion should] equal:kAMAValidPreActivationAppVersion];

            config.preActivationAppBuildNumber = kAMAValidPreActivationAppBuildNumber;
            [[config.preActivationAppBuildNumber should] equal:kAMAValidPreActivationAppBuildNumber];

            config.autoCrashTracking = NO;
            [[theValue(config.autoCrashTracking) should] beNo];
            
            config.probablyUnhandledCrashReporting = YES;
            [[theValue(config.probablyUnhandledCrashReporting) should] beYes];
            
            config.ignoredCrashSignals = @[ @SIGTRAP ];
            [[config.ignoredCrashSignals should] equal:@[ @SIGTRAP ]];
            
            config.applicationNotRespondingDetection = YES;
            [[theValue(config.applicationNotRespondingDetection) should] beYes];
            
            config.applicationNotRespondingWatchdogInterval = 6.0;
            [[theValue(config.applicationNotRespondingWatchdogInterval) should] equal:theValue(6.0)];
            
            config.applicationNotRespondingPingInterval = 0.3;
            [[theValue(config.applicationNotRespondingPingInterval) should] equal:theValue(0.3)];

            config.crashErrorEnvironmentCallback = AMAAppMetricaCrashesConfigurationTestsCrashCallback;
            [[theValue(config.crashErrorEnvironmentCallback ==
                       AMAAppMetricaCrashesConfigurationTestsCrashCallback) should] beYes];
        });
    });

    context(@"Pre-activation app version validation", ^{

        it(@"Should ignore empty and nil app versions", ^{
            config.preActivationAppVersion = kAMAValidPreActivationAppVersion;
            config.preActivationAppVersion = @"";
            config.preActivationAppVersion = nil;

            [[config.preActivationAppVersion should] equal:kAMAValidPreActivationAppVersion];
        });

        it(@"Should accept zero as an app build number", ^{
            config.preActivationAppBuildNumber = @"0";

            [[config.preActivationAppBuildNumber should] equal:@"0"];
        });

        it(@"Should accept the maximum unsigned 32-bit app build number", ^{
            config.preActivationAppBuildNumber = @"4294967295";

            [[config.preActivationAppBuildNumber should] equal:@"4294967295"];
        });

        it(@"Should ignore invalid and nil app build numbers", ^{
            config.preActivationAppBuildNumber = kAMAValidPreActivationAppBuildNumber;
            config.preActivationAppBuildNumber = @"-1";
            config.preActivationAppBuildNumber = @"1.5";
            config.preActivationAppBuildNumber = @"1 build";
            config.preActivationAppBuildNumber = @"4294967296";
            config.preActivationAppBuildNumber = nil;

            [[config.preActivationAppBuildNumber should] equal:kAMAValidPreActivationAppBuildNumber];
        });
    });
    
    context(@"Comparison and hashing", ^{
        
        it(@"Should consider two configurations with the same property values as equal", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            
            [[configA should] equal:configB];   // Uses isEqual:
            [[theValue([configA hash]) should] equal:theValue([configB hash])];
        });
        
        it(@"Should not consider two configurations with different property values as equal", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configB.autoCrashTracking = !configA.autoCrashTracking;
            
            [[configA shouldNot] equal:configB];  // Uses isEqual:
            [[theValue([configA hash]) shouldNot] equal:theValue([configB hash])];
        });

        it(@"Should compare app version and build number", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configA.preActivationAppVersion = @"1.0";
            configA.preActivationAppBuildNumber = @"1";

            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configB.preActivationAppVersion = @"2.0";
            configB.preActivationAppBuildNumber = @"2";

            [[configA shouldNot] equal:configB];
            [[theValue([configA hash]) shouldNot] equal:theValue([configB hash])];
        });

        it(@"Should not consider two configurations with different crash callbacks as equal", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configA.crashErrorEnvironmentCallback = AMAAppMetricaCrashesConfigurationTestsCrashCallback;
            configB.crashErrorEnvironmentCallback = AMAAppMetricaCrashesConfigurationTestsAnotherCrashCallback;

            [[configA shouldNot] equal:configB];
            [[theValue([configA hash]) shouldNot] equal:theValue([configB hash])];
        });
        
        it(@"Should produce consistent hash values for the same property configuration", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configA.preActivationAppVersion = kAMAValidPreActivationAppVersion;
            configA.preActivationAppBuildNumber = kAMAValidPreActivationAppBuildNumber;
            configA.autoCrashTracking = YES;
            configA.probablyUnhandledCrashReporting = YES;
            configA.ignoredCrashSignals = @[ @SIGABRT, @SIGILL ];
            configA.applicationNotRespondingDetection = YES;
            configA.applicationNotRespondingWatchdogInterval = 5.0;
            configA.applicationNotRespondingPingInterval = 0.2;
            
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configB.preActivationAppVersion = kAMAValidPreActivationAppVersion;
            configB.preActivationAppBuildNumber = kAMAValidPreActivationAppBuildNumber;
            configB.autoCrashTracking = YES;
            configB.probablyUnhandledCrashReporting = YES;
            configB.ignoredCrashSignals = @[ @SIGABRT, @SIGILL ];
            configB.applicationNotRespondingDetection = YES;
            configB.applicationNotRespondingWatchdogInterval = 5.0;
            configB.applicationNotRespondingPingInterval = 0.2;
            
            [[theValue([configA hash]) should] equal:theValue([configB hash])];
        });
        
        it(@"Should not produce the same hash for configurations with different properties", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configA.autoCrashTracking = YES;
            
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configB.autoCrashTracking = NO;
            
            [[theValue([configA hash]) shouldNot] equal:theValue([configB hash])];
        });
        
        it(@"Should not consider a configuration equal to its subclassed instance", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            
            TestConfigSubclass *configSubclassInstance = [[TestConfigSubclass alloc] init];
            
            [[configA shouldNot] equal:configSubclassInstance];
            [[theValue([configA hash]) shouldNot] equal:theValue([configSubclassInstance hash])];
        });
        
        it(@"Should not consider a configuration equal to a non-AMAAppMetricaCrashesConfiguration object", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            NSString *someString = @"A Random String";
            
            [[configA shouldNot] equal:someString];
        });
        
        it(@"Should consider two subclassed configurations with the same property values as equal", ^{
            TestConfigSubclass *configSubclassInstanceA = [[TestConfigSubclass alloc] init];
            TestConfigSubclass *configSubclassInstanceB = [[TestConfigSubclass alloc] init];
            
            [[configSubclassInstanceA should] equal:configSubclassInstanceB];
            [[theValue([configSubclassInstanceA hash]) should] equal:theValue([configSubclassInstanceB hash])];
        });
    });
});

SPEC_END
