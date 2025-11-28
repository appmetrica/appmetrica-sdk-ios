
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAReportRequestProvider.h"
#import "AMAReporterTestHelper.h"
#import "AMAEventStorage+TestUtilities.h"
#import "AMAReportRequest.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMAReportEventsBatch.h"
#import "AMAReporter.h"
#import "AMAReporterStorage.h"
#import "AMAReportRequestModel.h"
#import "AMAFileEventValue.h"
#import "AMAEvent.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReporterAutocollectedDataProviding.h"

SPEC_BEGIN(AMAReportRequestProviderTests)

describe(@"AMAReportRequestProvider", ^{
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAReportRequestProvider * __block requestProvider = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        requestProvider = [reporterTestHelper appReporter].reporterStorage.reportRequestProvider;
    });
    afterEach(^{
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [reporterTestHelper destub];
    });
    
	context(@"Provides requests array each having events with same session app state", ^{
        it(@"Should provide empty array if no events exist", ^{
            NSArray *requestModels = [requestProvider requestModels];
            [[requestModels should] beEmpty];
        });
        context(@"Provides one request for one event and one session", ^{
            NSArray * __block requestModels = nil;
            AMAReportRequestModel * __block requestModel = nil;
            beforeEach(^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                requestModels = [requestProvider requestModels];
                requestModel = requestModels.firstObject;
            });
            it(@"Should provide one request for one event and one session", ^{
                [[requestModels should] haveCountOf:1];
            });
            it(@"Should set 1 batch for request", ^{
                [[requestModel.eventsBatches should] haveCountOf:1];
            });
            it(@"Should set 3 events in batch for request", ^{
                AMAReportEventsBatch *batch = requestModel.eventsBatches[0];
                [[batch.events should] haveCountOf:3];
            });
        });
        context(@"Provides one request for two sessions with same state", ^{
            NSArray * __block requestModels = nil;
            AMAReportRequestModel * __block requestModel = nil;
            AMAAppStateManagerTestHelper *__block helper = nil;
            
            beforeEach(^{
                helper = [[AMAAppStateManagerTestHelper alloc] init];
                [helper stubApplicationState];
                [reporterTestHelper initReporterTwice];
                for (NSUInteger i = 0; i < 10; ++i) {
                    [reporterTestHelper sendEvent];
                }
                requestModels = [requestProvider requestModels];
                requestModel = requestModels.firstObject;
            });
            afterEach(^{
                [helper destubApplicationState];
            });
            
            it(@"Should provide one request", ^{
                [[requestModels should] haveCountOf:1];
            });
            it(@"Should set 2 batches", ^{
                [[requestModel.eventsBatches should] haveCountOf:2];
            });
            it(@"Should set 3 events for first batch", ^{
                AMAReportEventsBatch *batch = requestModel.eventsBatches[0];
                [[batch.events should] haveCountOf:3];
            });
            it(@"Should set 11 events for second batch", ^{
                AMAReportEventsBatch *batch = requestModel.eventsBatches[1];
                [[batch.events should] haveCountOf:11];
            });
        });
        context(@"Provides 2 requests for two sessions with different app states", ^{
            NSArray * __block requestModels = nil;
            AMAAppStateManagerTestHelper *__block helper = nil;
            beforeEach(^{
                helper = [[AMAAppStateManagerTestHelper alloc] init];
                [helper stubApplicationState];
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                helper.kitVersionName = @"9.8.7";
                [helper stubApplicationState];
                [reporterTestHelper restartApplication];
                [reporterTestHelper sendEvent];
                requestModels = [requestProvider requestModels];
            });
            afterEach(^{
                [helper destubApplicationState];
                [reporterTestHelper destub];
            });
            
            it(@"Should provide 2 requests", ^{
                [[requestModels should] haveCountOf:2];
            });
            it(@"Should set 1 batch for first request", ^{
                AMAReportRequestModel *requestModel = requestModels[0];
                [[requestModel.eventsBatches should] haveCountOf:1];
            });
            it(@"Should set 4 events for first batch in request", ^{
                AMAReportRequestModel *requestModel = requestModels[0];
                AMAReportEventsBatch *batch = requestModel.eventsBatches[0];
                [[batch.events should] haveCountOf:4];
            });
            it(@"Should set 1 batch for second request", ^{
                AMAReportRequestModel *requestModel = requestModels[1];
                [[requestModel.eventsBatches should] haveCountOf:1];
            });
            it(@"Should set 2 events for second request", ^{
                AMAReportRequestModel *requestModel = requestModels[1];
                AMAReportEventsBatch *batch = requestModel.eventsBatches[0];
                [[batch.events should] haveCountOf:2];
            });
        });
        context(@"Should group events by environment", ^{
            NSArray * __block requestModels = nil;
            AMAAppStateManagerTestHelper *__block helper = nil;
            beforeEach(^{
                helper = [[AMAAppStateManagerTestHelper alloc] init];
                [helper stubApplicationState];
            });
            afterEach(^{
                [helper destubApplicationState];
            });
            
            it(@"Should distinguish environment update", ^{
                AMAReporter *reporter = [reporterTestHelper appReporter];
                [reporter setAppEnvironmentValue:@"fizz" forKey:@"buzz"];
                [reporter reportEvent:[AMAReporterTestHelper testEventName] onFailure:nil];
                [reporter setAppEnvironmentValue:@"bar" forKey:@"buzz"];
                [reporter reportEvent:[AMAReporterTestHelper testEventName] onFailure:nil];
                requestModels = [requestProvider requestModels];
                // one for events with fizz:buzz
                // one for events with bar:buzz
                [[requestModels should] haveCountOf:2];
            });
            it(@"Should batch events with same environment", ^{
                AMAReporter *reporter = [reporterTestHelper appReporter];
                [reporter setAppEnvironmentValue:@"fizz" forKey:@"buzz"];
                [reporter reportEvent:[AMAReporterTestHelper testEventName] onFailure:nil];
                [reporter reportEvent:[AMAReporterTestHelper testEventName] onFailure:nil];
                requestModels = [requestProvider requestModels];
                // one for events with fizz:buzz
                [[requestModels should] haveCountOf:1];
            });
        });
        context(@"Should add additional api keys", ^{
            NSArray * __block requestModels = nil;
            NSArray *const additionalAPIKeys = @[@"additional_api_key_1", @"additional_api_key_2"];
            NSObject<AMAReporterAutocollectedDataProviding> *__block autocollectedDataProvider = nil;
            
            beforeEach(^{
                [reporterTestHelper initReporterAndSendEventWithParameters:nil];
                
                autocollectedDataProvider = [KWMock nullMockForProtocol:@protocol(AMAReporterAutocollectedDataProviding)];
                [autocollectedDataProvider stub:@selector(additionalAPIKeys) andReturn:additionalAPIKeys];
            });
            afterEach(^{
                [reporterTestHelper destub];
            });
            
            it(@"Should add additional api keys for request", ^{
                [[reporterTestHelper appReporter].reporterStorage setupAutocollectedDataProvider:autocollectedDataProvider];
                requestProvider = [reporterTestHelper appReporter].reporterStorage.reportRequestProvider;
                
                requestModels = [requestProvider requestModels];
                AMAReportRequestModel *requestModel = requestModels.firstObject;
                [[requestModel.additionalAPIKeys should] equal:additionalAPIKeys];
                
            });
        });
    });
});

SPEC_END
