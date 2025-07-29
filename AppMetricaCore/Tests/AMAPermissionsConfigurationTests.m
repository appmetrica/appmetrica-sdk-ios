
#import <Kiwi/Kiwi.h>

#import "AMATime.h"

#import "AMAPermissionsConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"

SPEC_BEGIN(AMAPermissionsConfigurationTests)

describe(@"AMAPermissionsConfiguration", ^{
         
    AMAPermissionsConfiguration *__block configuration = nil;
    AMAStartupParametersConfiguration *__block startupMock = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;

    beforeEach(^{
        AMAMetricaConfiguration *configMock = [AMAMetricaConfiguration mock];

        startupMock = [AMAStartupParametersConfiguration mock];
        persistentMock = [AMAMetricaPersistentConfiguration mock];

        [configMock stub:@selector(startup) andReturn:startupMock];
        [configMock stub:@selector(persistent) andReturn:persistentMock];

        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:configMock];
    
        configuration = [[AMAPermissionsConfiguration alloc] init];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });
    
    it(@"Should contain all permissions keys", ^{
        [[AMAPermissionsConfiguration.allKeys should] containObjectsInArray:@[
            kAMAPermissionKeyLocationAlways,
            kAMAPermissionKeyLocationWhenInUse,
        ]];
    });
    
    context(@"collectingEnabled", ^{
        
        it(@"Should return YES", ^{
            [startupMock stub:@selector(permissionsCollectingEnabled) andReturn:theValue(YES)];
            [[theValue(configuration.collectingEnabled) should] beYes];
        });
    
        it(@"Should return NO", ^{
            [startupMock stub:@selector(permissionsCollectingEnabled) andReturn:theValue(NO)];
            [[theValue(configuration.collectingEnabled) should] beNo];
        });
    });
         
    context(@"collectingInterval", ^{
        
        it(@"Should return configuration value", ^{
            [startupMock stub:@selector(permissionsCollectingForceSendInterval) andReturn:@123];
            [[theValue(configuration.collectingInterval) should] equal:theValue(123)];
        });
    
        it(@"Should return default value if configuration is empety", ^{
            [startupMock stub:@selector(permissionsCollectingForceSendInterval) andReturn:nil];
            [[theValue(configuration.collectingInterval) should] equal:theValue(1 * AMA_DAYS)];
        });
    });
         
    context(@"lastUpdateDate", ^{
        
        it(@"Should return configuration value", ^{
            NSDate *expectedDate = [NSDate date];
            [persistentMock stub:@selector(lastPermissionsUpdateDate) andReturn:expectedDate];
            [[configuration.lastUpdateDate should] equal:expectedDate];
        });
    
        it(@"Should set value to configuration", ^{
            NSDate *expectedDate = [NSDate date];
            [[persistentMock should] receive:@selector(setLastPermissionsUpdateDate:) withArguments:expectedDate];
            configuration.lastUpdateDate = expectedDate;
        });
    });
         
    context(@"keys", ^{
    
        it(@"Should return only available keys ", ^{
            [startupMock stub:@selector(permissionsCollectingList)
                    andReturn:@[
                        kAMAPermissionKeyLocationWhenInUse,
                        @"another_key",
                        @"yet_another_key",
                    ]];
            [[configuration.keys should] equal:@[ kAMAPermissionKeyLocationWhenInUse ]];
        });
    });
});

SPEC_END
