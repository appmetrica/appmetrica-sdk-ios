
#import <Kiwi/Kiwi.h>
#import "AMAInternalEventsReporter.h"
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventTypes.h"
#import "AMAStubReporterProvider.h"

SPEC_BEGIN(AMAInternalEventsReporterTests)

describe(@"AMAInternalEventsReporter", ^{

    id<AMAAsyncExecuting> __block executor = nil;
    AMAStubHostAppStateProvider *__block hostProvider = nil;
    KWMock<AMAAppMetricaReporting> __block *reporterMock = nil;
    AMAInternalEventsReporter *__block reporter = nil;

    beforeEach(^{
        executor = [AMACurrentQueueExecutor new];
        reporterMock = [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting)];
        AMAStubReporterProvider *reporterProvider = [AMAStubReporterProvider new];
        reporterProvider.reporter = reporterMock;
        
        hostProvider = [[AMAStubHostAppStateProvider alloc] init];

        reporter = [[AMAInternalEventsReporter alloc] initWithExecutor:executor
                                                      reporterProvider:reporterProvider
                                                     hostStateProvider:hostProvider];
    });

    context(@"Schema inconsistency event", ^{
        NSString *eventName = @"SchemaInconsistencyDetected";

        it(@"Should report event", ^{
            NSString *inconsistencyDescription = @"schema";
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, @{ @"schema: ": inconsistencyDescription }, kw_any()];
            [reporter reportSchemaInconsistencyWithDescription:inconsistencyDescription];
        });

        it(@"Should report event without parameters if no description", ^{
            NSString *inconsistencyDescription = nil;
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, [KWNull null], kw_any()];
            [reporter reportSchemaInconsistencyWithDescription:inconsistencyDescription];
        });
    });

    
    context(@"Search Ads", ^{
        it(@"Should report search ads attempt", ^{
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsAttempt", nil, kw_any()];
            
            [reporter reportSearchAdsAttempt];
        });
        it(@"Should report search ads token success", ^{
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsTokenSuccess", nil, kw_any()];
            
            [reporter reportSearchAdsTokenSuccess];
        });
    });
    
    context(@"Search Ads Completion", ^{
        NSString *const completionType = @"COMPLETION_TYPE";

        it(@"Should report without type", ^{
            NSDictionary *expectedParameters = @{ @"type": @"null" };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsCompletion", expectedParameters, kw_any()];
            [NSAssertionHandler stub:@selector(currentHandler)];
            [reporter reportSearchAdsCompletionWithType:nil parameters:nil];
        });

        it(@"Should report without parameters", ^{
            NSDictionary *expectedParameters = @{ @"type": completionType };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsCompletion", expectedParameters, kw_any()];
            [reporter reportSearchAdsCompletionWithType:completionType parameters:nil];
        });

        it(@"Should report with parameters", ^{
            NSDictionary *completionParameters = @{ @"foo": @"bar" };
            NSDictionary *expectedParameters = @{ @"type": @{ completionType: completionParameters } };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsCompletion", expectedParameters, kw_any()];
            [reporter reportSearchAdsCompletionWithType:completionType parameters:completionParameters];
        });
    });
    
    
    context(@"Extensions List", ^{
        it(@"Should report", ^{
            NSDictionary *expectedParameters = @{ @"foo": @"bar" };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"extensions_list", expectedParameters, kw_any()];
            [reporter reportExtensionsReportWithParameters:expectedParameters];
        });
        context(@"Exception", ^{
            it(@"Should report valid exception", ^{
                NSException *exception = [NSException exceptionWithName:@"foo" reason:@"bar" userInfo:nil];
                NSDictionary *expectedParameters = @{ @"foo": @"bar" };
                [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"extensions_list_collecting_exception", expectedParameters, kw_any()];
                [reporter reportExtensionsReportCollectingException:exception];
            });
            it(@"Should report nil exception", ^{
                [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                                 withArguments:@"extensions_list_collecting_exception", nil, kw_any()];
                [reporter reportExtensionsReportCollectingException:nil];
            });
        });

    });
    
    context(@"SKAD attribution parsing error", ^{
        it(@"Should report", ^{
            NSDictionary *params = @{ @"aa" : @"bb" };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"skad_attribution_parsing_error", params, kw_any()];
            [reporter reportSKADAttributionParsingError:params];
        });
    });

    context(@"hostStateDidChange", ^{
        it(@"Should register for session tracking", ^{
            [[hostProvider should] receive:@selector(setDelegate:)];

            reporter = [[AMAInternalEventsReporter alloc] initWithExecutor:executor
                                                          reporterProvider:nil
                                                         hostStateProvider:hostProvider];
        });
        
        it(@"Should resume session", ^{
            [[reporterMock should] receive:@selector(resumeSession)];
            
            hostProvider.hostState = AMAHostAppStateForeground;
        });
        it(@"Should pause session", ^{
            [[reporterMock should] receive:@selector(pauseSession)];
            
            hostProvider.hostState = AMAHostAppStateBackground;
        });
    });

    it(@"Should conform to AMAHostStateProviderDelegate", ^{
        [[reporter should] conformToProtocol:@protocol(AMAHostStateProviderDelegate)];
    });
    
    context(@"Event File Not Found", ^{
        it(@"Should report 'empty_crash' for AMAEventTypeProtobufCrash", ^{
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"empty_crash", @{ @"event_type": @(AMAEventTypeProtobufCrash) }, kw_any()];
            [reporter reportEventFileNotFoundForEventWithType:AMAEventTypeProtobufCrash];
        });
        
        it(@"Should report 'empty_crash' for AMAEventTypeProtobufANR", ^{
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"empty_crash", @{ @"event_type": @(AMAEventTypeProtobufANR) }, kw_any()];
            [reporter reportEventFileNotFoundForEventWithType:AMAEventTypeProtobufANR];
        });
        
        it(@"Should report 'event_value_file_not_found' for other event types", ^{
            NSUInteger otherEventType = 9999;
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"event_value_file_not_found", @{ @"event_type": @(otherEventType) }, kw_any()];
            [reporter reportEventFileNotFoundForEventWithType:otherEventType];
        });
        
    });

});

SPEC_END
