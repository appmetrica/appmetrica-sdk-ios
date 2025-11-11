 
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAAdServicesReportingController.h"
#import "AMAAdServicesDataProvider.h"
#import "AMAReporterStateStorage.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAReporter.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAInternalEventsReporter.h"

SPEC_BEGIN(AMAAdServicesReportingControllerTests)

describe(@"AMAAdServicesReportingController", ^{
    
    static NSString *const kAMATokenMock = @"ASA_TOKEN";
    NSDate *const kAMAFirstStartupUpdateDate = [NSDate dateWithTimeIntervalSince1970:1];
    NSDate *const kAMAStartupUpdatedAt = [NSDate dateWithTimeIntervalSince1970:4];
    NSNumber *const kAMAServerTimeOffset = @0;
    
    AMAAdServicesReportingController *__block controller = nil;
    
    AMAAdServicesDataProvider *__block dataProviderMock = nil;
    AMAReporterStateStorage *__block stateStorageMock = nil;
    AMAMetricaConfiguration *__block configurationMock = nil;
    AMAReporter *__block reporterMock = nil;
    AMAInternalEventsReporter *__block internalEventsReporter = nil;
    
    beforeEach(^{
        stateStorageMock = [AMAReporterStateStorage nullMock];
        
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configurationMock = [AMAMetricaConfiguration sharedInstance];
        
        [configurationMock.persistent stub:@selector(firstStartupUpdateDate) andReturn:kAMAFirstStartupUpdateDate];
        [configurationMock.persistent stub:@selector(startupUpdatedAt) andReturn:kAMAStartupUpdatedAt];
        [configurationMock.startup stub:@selector(serverTimeOffset) andReturn:kAMAServerTimeOffset];
        
        dataProviderMock = [AMAAdServicesDataProvider mock];
        [dataProviderMock stub:@selector(tokenWithError:) andReturn:kAMATokenMock];
        
        reporterMock = [AMAReporter nullMock];
        [AMAAppMetrica stub:@selector(reporterForAPIKey:) andReturn:reporterMock];
        
        internalEventsReporter = [AMAInternalEventsReporter nullMock];
        [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];
        
        
        controller = [[AMAAdServicesReportingController alloc] initWithApiKey:@"API_KEY"
                                                              reporterStorage:stateStorageMock
                                                                configuration:configurationMock
                                                                 dataProvider:dataProviderMock];
    });
    
    context(@"Default config values", ^{
        
        it(@"Should not report if first interval hasn't passed", ^{
            [NSDate stub:@selector(date) andReturn:kAMAFirstStartupUpdateDate];
            [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
            [controller reportTokenIfNeeded];
        });
        
        it(@"Should not report if startup is unavailable", ^{
            [configurationMock clearStubs];
            [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
            [controller reportTokenIfNeeded];
        });
        
        it(@"Should not report if token send date is distant past", ^{
            [stateStorageMock stub:@selector(lastASATokenSendDate) andReturn:[NSDate distantPast]];
            [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
            [controller reportTokenIfNeeded];
        });
        
        it(@"Should not report if send date and startup is unavailable", ^{
            [configurationMock clearStubs];
            [stateStorageMock stub:@selector(lastASATokenSendDate) andReturn:[NSDate distantPast]];
            [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
            [controller reportTokenIfNeeded];
        });
        
        context(@"Delay passed", ^{
            
            static NSTimeInterval const kAMA12Hours = 12 * 60 * 60;
            static NSTimeInterval const kAMA1Day = kAMA12Hours * 2;
            
            NSDate *const kAMADelayExecutionDate = [kAMAFirstStartupUpdateDate dateByAddingTimeInterval:kAMA12Hours];
            
            beforeEach(^{
                [configurationMock.persistent stub:@selector(startupUpdatedAt) andReturn:kAMADelayExecutionDate];
            });
            
            it(@"Should mark ASA token time", ^{
                [[stateStorageMock should] receive:@selector(markASATokenSentNow)];
                [controller reportTokenIfNeeded];
            });
            
            it(@"Should report with correct content", ^{
                [[reporterMock should] receive:@selector(reportASATokenEventWithParameters:onFailure:)
                                 withArguments:@{ @"asaToken" : kAMATokenMock }, kw_any()];
                [controller reportTokenIfNeeded];
            });
            
            it(@"Should report ads token success internal event", ^{
                [[internalEventsReporter should] receive:@selector(reportSearchAdsTokenSuccess)];
                
                [controller reportTokenIfNeeded];
            });
            
            it(@"Should report if 12 hours passed after startup", ^{
                [[reporterMock should] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
                [controller reportTokenIfNeeded];
            });
            
            context(@"Interval", ^{
                
                NSDate *const kAMAIntervalExecutionDate = [kAMADelayExecutionDate dateByAddingTimeInterval:kAMA12Hours];
                
                beforeEach(^{
                    [stateStorageMock stub:@selector(lastASATokenSendDate) andReturn:kAMADelayExecutionDate];
                });
                
                it(@"Should report every 12 hours", ^{
                    [NSDate stub:@selector(date) andReturn:kAMAIntervalExecutionDate];
                    
                    [[reporterMock should] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
                    [controller reportTokenIfNeeded];
                });
                
                it(@"Should not report twice within one interval", ^{
                    [stateStorageMock stub:@selector(lastASATokenSendDate) andReturn:kAMAIntervalExecutionDate];
                    [NSDate stub:@selector(date) andReturn:[kAMAIntervalExecutionDate dateByAddingTimeInterval:1]];
                    
                    [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
                    [controller reportTokenIfNeeded];
                });
                
                context(@"Gap", ^{
                    
                    NSDate *const kAMAEndDate = [kAMAFirstStartupUpdateDate dateByAddingTimeInterval:kAMA1Day * 7];
                    
                    beforeEach(^{
                        [configurationMock.persistent stub:@selector(startupUpdatedAt) andReturn:kAMAEndDate];
                    });
                    
                    it(@"Should not report after 7 day gap", ^{
                        [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
                        [controller reportTokenIfNeeded];
                    });
                    
                    it(@"Should not report after passing interval", ^{
                        NSDate *date = [kAMAEndDate dateByAddingTimeInterval:kAMA12Hours + 1];
                        [NSDate stub:@selector(date) andReturn:date];
                        [configurationMock.persistent stub:@selector(startupUpdatedAt) andReturn:date];
                        [[reporterMock shouldNot] receive:@selector(reportASATokenEventWithParameters:onFailure:)];
                        [controller reportTokenIfNeeded];
                    });
                });
            });
        });
    });
});

SPEC_END
