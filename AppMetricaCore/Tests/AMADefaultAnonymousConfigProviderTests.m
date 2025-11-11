
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"

SPEC_BEGIN(AMADefaultAnonymousConfigProviderTests)

describe(@"AMADefaultAnonymousConfigProvider", ^{
    
    context(@"configuration", ^{
        it(@"should return a valid configuration with the anonymous API key", ^{
            AMADefaultAnonymousConfigProvider *provider = [[AMADefaultAnonymousConfigProvider alloc] init];
            AMAAppMetricaConfiguration *config = [provider configuration];
            
            [[config.APIKey should] equal:@"629a824d-c717-4ba5-bc0f-3f3968554d01"];
        });
        
        it(@"should set default values in configuration", ^{
            AMADefaultAnonymousConfigProvider *provider = [[AMADefaultAnonymousConfigProvider alloc] init];
            AMAAppMetricaConfiguration *config = [provider configuration];
            
            [[theValue(config.revenueAutoTrackingEnabled) should] equal:theValue(kAMADefaultRevenueAutoTrackingEnabled)];
            [[theValue(config.appOpenTrackingEnabled) should] equal:theValue(kAMADefaultAppOpenTrackingEnabled)];
            [[theValue(config.handleFirstActivationAsUpdate) should] beNo];
            [[theValue(config.handleActivationAsSessionStart) should] beNo];
            [[theValue(config.sessionsAutoTracking) should] beYes];
            [[theValue(config.allowsBackgroundLocationUpdates) should] beNo];
            [[theValue(config.areLogsEnabled) should] beNo];
            [[theValue(config.accurateLocationTracking) should] beNo];
            [[theValue(config.locationTracking) should] beYes];
            [[theValue(config.dataSendingEnabled) should] beYes];
            
            [[theValue(config.sessionTimeout) should] equal:theValue(kAMASessionValidIntervalInSecondsDefault)];
            [[theValue(config.dispatchPeriod) should] equal:theValue(kAMADefaultDispatchPeriodSeconds)];
            [[theValue(config.maxReportsCount) should] equal:theValue(kAMAAutomaticReporterDefaultMaxReportsCount)];
            [[theValue(config.maxReportsInDatabaseCount) should] equal:theValue(kAMAMaxReportsInDatabaseCount)];
            
            [[config.appEnvironment should] beNil];
        });
        
        it(@"should return anonymous api key", ^{
            [[AMADefaultAnonymousConfigProvider.anonymousAPIKey should] equal:@"629a824d-c717-4ba5-bc0f-3f3968554d01"];
        });
    });
    
});

SPEC_END
