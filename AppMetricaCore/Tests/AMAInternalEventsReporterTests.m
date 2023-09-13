
#import <Kiwi/Kiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAInternalEventsReporter.h"
#import "AMAStubReporterProvider.h"
#import "AMAStubHostAppStateProvider.h"

SPEC_BEGIN(AMAInternalEventsReporterTests)

describe(@"AMAInternalEventsReporter", ^{

    id<AMAExecuting> __block executor = nil;
    AMAStubHostAppStateProvider *__block hostProvider = nil;
    KWMock<AMAAppMetricaReporting > __block *reporterMock = nil;
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

    context(@"Transaction failure event", ^{
        NSString *eventName = @"TransactionFailure";

        NSString *transactionID = @"Transaction ID";
        NSString *transactionOwnerName = @"Owner name";
        NSString *rollbackContent = @"Rollback content";
        NSString *exceptionName = @"Exception name";
        NSString *exceptionReason = @"Exception reason";
        NSArray *exceptionBacktrace = @[ @"line1", @"line2" ];
        NSDictionary *exceptionUserInfo = @{ @"key": @"value" };
        NSException *__block rollbackException = nil;

        beforeEach(^{
            rollbackException = [[NSException alloc] initWithName:exceptionName
                                                           reason:exceptionReason
                                                         userInfo:exceptionUserInfo];
            [rollbackException stub:@selector(callStackSymbols) andReturn:exceptionBacktrace];
        });

        it(@"Should report event if rollback failed", ^{
            NSDictionary *parameters = @{
                transactionID : @{
                    @"name" : transactionOwnerName,
                    @"rollback" : @"failed",
                    @"rollbackcontent" : rollbackContent,
                    @"exception" : @{
                        @"name" : exceptionName,
                        @"reason" : exceptionReason,
                        @"backtrace" : exceptionBacktrace,
                        @"userInfo" : rollbackException.userInfo
                    }
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:transactionID
                                          ownerName:transactionOwnerName
                                    rollbackContent:rollbackContent
                                  rollbackException:rollbackException
                                     rollbackFailed:YES];
        });

        it(@"Should report event if rollback succeeded", ^{
            NSDictionary *parameters = @{
                transactionID : @{
                    @"name" : transactionOwnerName,
                    @"rollback" : @"succeeded",
                    @"rollbackcontent" : rollbackContent
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:transactionID
                                          ownerName:transactionOwnerName
                                    rollbackContent:rollbackContent
                                  rollbackException:nil
                                     rollbackFailed:NO];
        });

        it(@"Should report absent transaction ID as Unknown", ^{
            NSDictionary *parameters = @{
                @"Unknown" : @{
                    @"name" : transactionOwnerName,
                    @"rollback" : @"succeeded",
                    @"rollbackcontent" : rollbackContent
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:nil
                                          ownerName:transactionOwnerName
                                    rollbackContent:rollbackContent
                                  rollbackException:nil
                                     rollbackFailed:NO];
        });

        it(@"Should report event without transaction owner name", ^{
            NSDictionary *parameters = @{
                transactionID : @{
                    @"rollback" : @"succeeded",
                    @"rollbackcontent" : rollbackContent
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:transactionID
                                          ownerName:nil
                                    rollbackContent:rollbackContent
                                  rollbackException:nil
                                     rollbackFailed:NO];
        });

        it(@"Should report event without rollback content", ^{
            NSDictionary *parameters = @{
                transactionID : @{
                    @"name" : transactionOwnerName,
                    @"rollback" : @"succeeded"
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:transactionID
                                          ownerName:transactionOwnerName
                                    rollbackContent:nil
                                  rollbackException:nil
                                     rollbackFailed:NO];
        });

        it(@"Should report event if rollback failed without exception", ^{
            NSDictionary *parameters = @{
                transactionID : @{
                    @"name" : transactionOwnerName,
                    @"rollback" : @"failed",
                    @"rollbackcontent" : rollbackContent
                }
            };
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:eventName, parameters, kw_any()];
            [reporter reportFailedTransactionWithID:transactionID
                                          ownerName:transactionOwnerName
                                    rollbackContent:rollbackContent
                                  rollbackException:nil
                                     rollbackFailed:YES];
        });
    });

    context(@"Search Ads Attempt", ^{
        it(@"Should report", ^{
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"AppleSearchAdsAttempt", nil, kw_any()];
            [reporter reportSearchAdsAttempt];
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
    
    context(@"Corrupted crash reports", ^{
        
        it(@"Should report of corrupted report", ^{
            NSDictionary *expecrtedUserInfo = @{ @"foo": @"bar" };
            NSString *expectedErrorDomain = @"test_domain";
            NSInteger exprecredCode = 123;
            NSError *error = [NSError errorWithDomain:expectedErrorDomain
                                                 code:exprecredCode
                                             userInfo:expecrtedUserInfo];
            
            NSDictionary *expectedParameters = @{
                                                 @"domain" : expectedErrorDomain,
                                                 @"error_code" : @(exprecredCode),
                                                 @"error_details" : expecrtedUserInfo.description,
                                                 };
            
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"corrupted_crash_report", expectedParameters, kw_any()];
            [reporter reportCorruptedCrashReportWithError:error];
        });
        
        it(@"Should report of recrash", ^{
            NSDictionary *expecrtedUserInfo = @{ @"foo": @"bar" };
            NSString *expectedErrorDomain = @"test_domain";
            NSInteger exprecredCode = 123;
            NSError *error = [NSError errorWithDomain:expectedErrorDomain
                                                 code:exprecredCode
                                             userInfo:expecrtedUserInfo];
            
            NSDictionary *expectedParameters = @{
                                                 @"domain" : expectedErrorDomain,
                                                 @"error_code" : @(exprecredCode),
                                                 @"error_details" : expecrtedUserInfo.description,
                                                 };
            
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"crash_report_recrash", expectedParameters, kw_any()];
            [reporter reportRecrashWithError:error];
        });
        
        it(@"Should report of unsupported crash report version", ^{
            NSDictionary *expecrtedUserInfo = @{ @"foo": @"bar" };
            NSString *expectedErrorDomain = @"test_domain";
            NSInteger exprecredCode = 123;
            NSError *error = [NSError errorWithDomain:expectedErrorDomain
                                                 code:exprecredCode
                                             userInfo:expecrtedUserInfo];
            
            NSDictionary *expectedParameters = @{
                                                 @"domain" : expectedErrorDomain,
                                                 @"error_code" : @(exprecredCode),
                                                 @"error_details" : expecrtedUserInfo.description,
                                                 };
            
            [[reporterMock should] receive:@selector(reportEvent:parameters:onFailure:)
                             withArguments:@"crash_report_version_unsupported", expectedParameters, kw_any()];
            [reporter reportUnsupportedCrashReportVersionWithError:error];
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

});

SPEC_END
