
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAppMetricaConfigurationManager.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAReporterConfiguration.h"
#import "AMAAppMetricaPreloadInfo.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAMetricaConfiguration.h"
#import "AMALocationManager.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMADatabaseQueueProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAAdProvider.h"
#import "AMAPermissionResolving.h"
#import "AMAAdProviderResolver.h"
#import "AMAAppMetricaLibraryAdapterConfiguration.h"

SPEC_BEGIN(AMAAppMetricaConfigurationManagerTests)

describe(@"AMAAppMetricaConfigurationManager", ^{
    NSString *const anonymousApiKey = @"629a824d-c717-4ba5-bc0f-3f3968554d01";
    NSString *const apiKey = @"api_key";
    
    AMAAppMetricaConfigurationManager *__block configManager = nil;
    __block id<AMAAsyncExecuting,
 AMASyncExecuting> executor = nil;
    AMADispatchStrategiesContainer *__block strategiesContainerMock = nil;
    AMAMetricaConfiguration *__block metricaConfigurationMock = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;
    AMAMetricaInMemoryConfiguration *__block inMemoryConfig = nil;
    AMADataSendingRestrictionController *__block restrictionController = nil;
    AMAConfigForAnonymousActivationProvider *__block anonymousConfigProviderMock = nil;
    
    AMALocationManager *__block locationManager = nil;
    id<AMAPermissionResolvingInput> __block locationResolver = nil;
    
    AMAAdProvider *__block adProvider = nil;
    AMAAdProviderResolver *__block adResolver = nil;
    
    
    beforeEach(^{
        executor = [AMACurrentQueueExecutor new];
        strategiesContainerMock = [AMADispatchStrategiesContainer nullMock];
        
        metricaConfigurationMock = [AMAMetricaConfiguration nullMock];
        persistentMock = [AMAMetricaPersistentConfiguration nullMock];
        [metricaConfigurationMock stub:@selector(persistent) andReturn:persistentMock];
        inMemoryConfig = [AMAMetricaInMemoryConfiguration new];
        [metricaConfigurationMock stub:@selector(inMemory) andReturn:inMemoryConfig];
        
        locationManager = [AMALocationManager nullMock];
        locationResolver = [KWMock mockForProtocol:@protocol(AMAPermissionResolvingInput)];
        
        adProvider = [AMAAdProvider nullMock];
        adResolver = [AMAAdProviderResolver nullMock];
        
        restrictionController = [AMADataSendingRestrictionController sharedInstance];
        anonymousConfigProviderMock = [AMAConfigForAnonymousActivationProvider nullMock];
        
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfigurationMock];

        configManager = [[AMAAppMetricaConfigurationManager alloc] initWithExecutor:executor
                                                                strategiesContainer:strategiesContainerMock
                                                               metricaConfiguration:metricaConfigurationMock
                                                              restrictionController:restrictionController
                                                            anonymousConfigProvider:anonymousConfigProviderMock locationManager:locationManager
                                                                   locationResolver:locationResolver
                                                                 adProviderResolver:adResolver];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });
    
    context(@"updateMainConfiguration", ^{
        AMAAppMetricaConfiguration *__block mockConfig = nil;
        NSString *const apiKey = @"api_key";
        beforeEach(^{
            mockConfig = [AMAAppMetricaConfiguration nullMock];
            
            [(NSObject *)locationResolver stub:@selector(updateBoolValue:isAnonymous:)];
            [(NSObject *)adResolver stub:@selector(updateBoolValue:isAnonymous:)];
        });
        it(@"should update last main api key in local storage", ^{
            [mockConfig stub:@selector(APIKey) andReturn:apiKey];
            [[persistentMock should] receive:@selector(setRecentMainApiKey:) withArguments:apiKey];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update client configuration in local storage", ^{
            [[persistentMock should] receive:@selector(setAppMetricaClientConfiguration:) withArguments:mockConfig];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        context(@"CustomVersion", ^{
            NSString *const appVersion = @"app.version";
            NSString *const validBuildNumber = @"282";
            
            it(@"should update custom version configuration with invalid build number", ^{
                NSString *const invalidAppBuildNumber = @"282.1";
                [mockConfig stub:@selector(appVersion) andReturn:appVersion];
                [mockConfig stub:@selector(appBuildNumber) andReturn:invalidAppBuildNumber];
                
                [configManager updateMainConfiguration:mockConfig];
                
                [[inMemoryConfig.appVersion should] equal:appVersion];
                [[inMemoryConfig.appBuildNumberString should] beNil];
                [[theValue(inMemoryConfig.appBuildNumber) should] equal:theValue([[AMAPlatformDescription appBuildNumber] intValue])];
            });
            it(@"should update custom version configuration with valid build number", ^{
                [mockConfig stub:@selector(appVersion) andReturn:appVersion];
                [mockConfig stub:@selector(appBuildNumber) andReturn:validBuildNumber];
                
                [configManager updateMainConfiguration:mockConfig];
                
                [[inMemoryConfig.appVersion should] equal:appVersion];
                [[inMemoryConfig.appBuildNumberString should] equal:validBuildNumber];
                [[theValue(inMemoryConfig.appBuildNumber) should] equal:theValue(282)];
            });
        });
        it(@"should update reporter configuration", ^{
            const NSUInteger sessionTimeout = 120;
            const NSUInteger maxReportsCount = 100;
            const NSUInteger maxReportsInDatabaseCount = 500;
            const NSUInteger dispatchPeriod = 90;
            
            AMAMutableReporterConfiguration *__block reporterConfig = [[AMAMutableReporterConfiguration alloc] initWithAPIKey:anonymousApiKey];
            [metricaConfigurationMock stub:@selector(appConfiguration) andReturn:reporterConfig];
            
            [metricaConfigurationMock stub:@selector(setAppConfiguration:) withBlock:^id(NSArray *params) {
                AMAMutableReporterConfiguration *newAppConfiguration = params.firstObject;
                reporterConfig = newAppConfiguration;
                return nil;
            }];
            
            [mockConfig stub:@selector(APIKey) andReturn:apiKey];
            [mockConfig stub:@selector(sessionTimeout) andReturn:theValue(sessionTimeout)];
            [mockConfig stub:@selector(maxReportsCount) andReturn:theValue(maxReportsCount)];
            [mockConfig stub:@selector(maxReportsInDatabaseCount) andReturn:theValue(maxReportsInDatabaseCount)];
            [mockConfig stub:@selector(dispatchPeriod) andReturn:theValue(dispatchPeriod)];
            [mockConfig stub:@selector(areLogsEnabled) andReturn:theValue(YES)];
            [mockConfig stub:@selector(dataSendingEnabled) andReturn:theValue(YES)];
            [mockConfig stub:@selector(handleFirstActivationAsUpdate) andReturn:theValue(YES)];
            [mockConfig stub:@selector(handleActivationAsSessionStart) andReturn:theValue(YES)];
            [mockConfig stub:@selector(sessionsAutoTracking) andReturn:theValue(NO)];
            
            [configManager updateMainConfiguration:mockConfig];
            
            [[reporterConfig.APIKey should] equal:apiKey];
            [[theValue(reporterConfig.sessionTimeout) should] equal:theValue(sessionTimeout)];
            [[theValue(reporterConfig.maxReportsInDatabaseCount) should] equal:theValue(maxReportsInDatabaseCount)];
            [[theValue(reporterConfig.dispatchPeriod) should] equal:theValue(dispatchPeriod)];
            [[theValue(reporterConfig.logsEnabled) should] equal:theValue(YES)];
            [[theValue(reporterConfig.dataSendingEnabled) should] equal:theValue(YES)];
            
            [[theValue(inMemoryConfig.handleFirstActivationAsUpdate) should] beYes];
            [[theValue(inMemoryConfig.handleActivationAsSessionStart) should] beYes];
            [[theValue(inMemoryConfig.sessionsAutoTracking) should] beNo];
        });
        it(@"should update preload info", ^{
            AMAAppMetricaPreloadInfo *preloadInfo = [AMAAppMetricaPreloadInfo nullMock];
            [mockConfig stub:@selector(preloadInfo) andReturn:preloadInfo];
            
            [configManager updateMainConfiguration:mockConfig];
            
            [[configManager.preloadInfo should] equal:preloadInfo];
        });
        it(@"should update user startup hosts", ^{
            NSArray *userStartupHosts = @[@"host"];
            [mockConfig stub:@selector(customHosts) andReturn:userStartupHosts];
            
            [[persistentMock should] receive:@selector(setUserStartupHosts:) withArguments:userStartupHosts];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update data sending configuration with undefined restriction if data sending is disabled", ^{
            [mockConfig stub:@selector(APIKey) andReturn:apiKey];
            [mockConfig stub:@selector(dataSendingEnabledState) andReturn:@(0)];
            
            [[restrictionController should] receive:@selector(setMainApiKey:) withArguments:apiKey];
            [[restrictionController should] receive:@selector(setMainApiKeyRestriction:)
                                      withArguments:theValue(AMADataSendingRestrictionForbidden)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update data sending configuration with undefined restriction if data sending is not set", ^{
            [mockConfig stub:@selector(APIKey) andReturn:apiKey];
            
            [[restrictionController should] receive:@selector(setMainApiKey:) withArguments:apiKey];
            [[restrictionController should] receive:@selector(setMainApiKeyRestriction:)
                                      withArguments:theValue(AMADataSendingRestrictionUndefined)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update data sending configuration with allowed restriction if data sending is enabled", ^{
            [mockConfig stub:@selector(APIKey) andReturn:apiKey];
            [mockConfig stub:@selector(dataSendingEnabledState) andReturn:@(1)];
            
            [[restrictionController should] receive:@selector(setMainApiKey:) withArguments:apiKey];
            [[restrictionController should] receive:@selector(setMainApiKeyRestriction:)
                                      withArguments:theValue(AMADataSendingRestrictionAllowed)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update location configuration", ^{
            CLLocation *customLocation = [[CLLocation alloc] init];
            [mockConfig stub:@selector(accurateLocationTracking) andReturn:theValue(YES)];
            [mockConfig stub:@selector(locationTrackingState) andReturn:@(YES)];
            [mockConfig stub:@selector(locationTracking) andReturn:theValue(YES)];
            [mockConfig stub:@selector(customLocation) andReturn:customLocation];
            
            [[(NSObject *)locationResolver should] receive:@selector(updateBoolValue:isAnonymous:)
                                             withArguments:theValue(YES), theValue(NO)];
            [[locationManager should] receive:@selector(setLocation:) withArguments:customLocation];
            [[locationManager should] receive:@selector(setAccurateLocationEnabled:) withArguments:theValue(YES)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update adv", ^{
            [mockConfig stub:@selector(advertisingIdentifierTrackingEnabledState) andReturn:@(YES)];
            
            [[(NSObject *)adResolver should] receive:@selector(updateBoolValue:isAnonymous:)
                                       withArguments:@(YES), theValue(NO)];
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should update log configuration", ^{
            [mockConfig stub:@selector(areLogsEnabled) andReturn:theValue(YES)];
            
            [[AMAAppMetrica should] receive:@selector(setLogs:) withArguments:theValue(YES)];
            [[[AMADatabaseQueueProvider sharedInstance] should] receive:@selector(setLogsEnabled:) withArguments:theValue(YES)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should handle configuration update", ^{
            [[strategiesContainerMock should] receive:@selector(handleConfigurationUpdate)];
            
            [configManager updateMainConfiguration:mockConfig];
        });
        it(@"should not update configuration if nil is passed", ^{
            [[AMAAppMetrica shouldNot] receive:@selector(setLogs:)];
            [[strategiesContainerMock shouldNot] receive:@selector(handleConfigurationUpdate)];
            
            [configManager updateMainConfiguration:nil];
        });
    });
    
    context(@"updateReporterConfiguration", ^{
        AMAReporterConfiguration *__block mockReporterConfig = nil;
        beforeEach(^{
            mockReporterConfig = [AMAReporterConfiguration nullMock];
        });
        it(@"should update data sending configuration with undefined restriction if data sending is disabled", ^{
            [mockReporterConfig stub:@selector(APIKey) andReturn:apiKey];
            [mockReporterConfig stub:@selector(dataSendingEnabledState) andReturn:@(0)];
            
            [[restrictionController should] receive:@selector(setReporterRestriction:forApiKey:)
                                      withArguments:theValue(AMADataSendingRestrictionForbidden), apiKey];
            
            [configManager updateReporterConfiguration:mockReporterConfig];
        });
        
        it(@"should update data sending configuration with undefined restriction if data sending is enabled", ^{
            [mockReporterConfig stub:@selector(APIKey) andReturn:apiKey];
            [mockReporterConfig stub:@selector(dataSendingEnabledState) andReturn:@(1)];
            
            [[restrictionController should] receive:@selector(setReporterRestriction:forApiKey:)
                                      withArguments:theValue(AMADataSendingRestrictionAllowed), apiKey];
            
            [configManager updateReporterConfiguration:mockReporterConfig];
        });
        
        it(@"should update data sending configuration with undefined restriction if data sending is not set", ^{
            [mockReporterConfig stub:@selector(APIKey) andReturn:apiKey];
            
            [[restrictionController should] receive:@selector(setReporterRestriction:forApiKey:)
                                      withArguments:theValue(AMADataSendingRestrictionUndefined), apiKey];
            
            [configManager updateReporterConfiguration:mockReporterConfig];
        });
        it(@"should handle configuration update", ^{
            [[strategiesContainerMock should] receive:@selector(handleConfigurationUpdate)];
            
            [configManager updateReporterConfiguration:mockReporterConfig];
        });
        it(@"should update configuration", ^{
            [[metricaConfigurationMock should] receive:@selector(setConfiguration:) withArguments:mockReporterConfig];
            
            [configManager updateReporterConfiguration:mockReporterConfig];
        });
    });
    
    context(@"updateAnonymousConfigurationWithLibraryAdapterConfiguration", ^{
        
        AMAAppMetricaConfiguration *__block configMock = nil;
        AMAAppMetricaLibraryAdapterConfiguration *__block adapterConfig = nil;
        
        beforeEach(^{
            configMock = [AMAAppMetricaConfiguration nullMock];
            [configMock stub:@selector(APIKey) andReturn:@"629a824d-c717-4ba5-bc0f-3f3968554d01"];
            [anonymousConfigProviderMock stub:@selector(configuration) andReturn:configMock];
            
            [configMock stub:@selector(setAdvertisingIdentifierTrackingEnabled:)];
            [configMock stub:@selector(setLocationTracking:)];
            
            adapterConfig = [AMAAppMetricaLibraryAdapterConfiguration new];
            adapterConfig.advertisingIdentifierTrackingEnabled = YES;
            adapterConfig.locationTrackingEnabled = YES;
        });
        
        it(@"should setup anonymousConfig", ^{
            [[configMock should] receive:@selector(setAdvertisingIdentifierTrackingEnabled:) withArguments:theValue(YES)];
            [[configMock should] receive:@selector(setLocationTracking:) withArguments:theValue(YES)];
            
            [configManager updateAnonymousConfigurationWithLibraryAdapterConfiguration:adapterConfig];
        });
        
        it(@"should return updated config as anonymousConfiguration", ^{
            [configManager updateAnonymousConfigurationWithLibraryAdapterConfiguration:adapterConfig];
            [[configManager.anonymousConfiguration should] equal:configMock];
        });
        
    });
    
    context(@"anonymousConfiguration", ^{
        it(@"should return the anonymous configuration from the provider", ^{
            AMAAppMetricaConfiguration *configMock = [AMAAppMetricaConfiguration nullMock];
            [anonymousConfigProviderMock stub:@selector(configuration) andReturn:configMock];
            
            [[[configManager anonymousConfiguration] should] equal:configMock];
        });
    });
});

SPEC_END
