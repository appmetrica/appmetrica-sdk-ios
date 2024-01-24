#import <Kiwi/Kiwi.h>

#import "AMAAppMetricaCrashesConfiguration.h"

@interface TestConfigSubclass : AMAAppMetricaCrashesConfiguration
@end

@implementation TestConfigSubclass
@end

SPEC_BEGIN(AMAAppMetricaCrashesConfigurationTests)

describe(@"AMAAppMetricaCrashesConfiguration", ^{
    
    let(config, ^{ return [[AMAAppMetricaCrashesConfiguration alloc] init]; });
    
    context(@"Default property values", ^{
        
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
    });
    
    context(@"NSCopying behavior", ^{
        
        it(@"Should produce a correct copy with the same property values", ^{
            config.autoCrashTracking = NO;
            config.probablyUnhandledCrashReporting = YES;
            config.ignoredCrashSignals = @[ @SIGABRT, @SIGILL ];
            config.applicationNotRespondingDetection = YES;
            config.applicationNotRespondingWatchdogInterval = 5.0;
            config.applicationNotRespondingPingInterval = 0.2;
            
            AMAAppMetricaCrashesConfiguration *configCopy = [config copy];
            
            [[theValue(configCopy.autoCrashTracking) should] beNo];
            [[theValue(configCopy.probablyUnhandledCrashReporting) should] beYes];
            [[configCopy.ignoredCrashSignals should] equal:@[ @SIGABRT, @SIGILL ]];
            [[theValue(configCopy.applicationNotRespondingDetection) should] beYes];
            [[theValue(configCopy.applicationNotRespondingWatchdogInterval) should] equal:theValue(5.0)];
            [[theValue(configCopy.applicationNotRespondingPingInterval) should] equal:theValue(0.2)];
        });
    });
    
    context(@"Property mutability", ^{
        
        it(@"Should allow changing property values", ^{
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
        
        it(@"Should produce consistent hash values for the same property configuration", ^{
            AMAAppMetricaCrashesConfiguration *configA = [[AMAAppMetricaCrashesConfiguration alloc] init];
            configA.autoCrashTracking = YES;
            configA.probablyUnhandledCrashReporting = YES;
            configA.ignoredCrashSignals = @[ @SIGABRT, @SIGILL ];
            configA.applicationNotRespondingDetection = YES;
            configA.applicationNotRespondingWatchdogInterval = 5.0;
            configA.applicationNotRespondingPingInterval = 0.2;
            
            AMAAppMetricaCrashesConfiguration *configB = [[AMAAppMetricaCrashesConfiguration alloc] init];
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
