
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMADispatcher.h"
#import "AMADispatcherDelegate.h"
#import "AMAEvent.h"
#import "AMAReportEventsBatch.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAReportsController.h"
#import "AMAReportRequestProvider.h"
#import "AMAReporterStorage.h"
#import "AMAReporterStateStorage.h"
#import "AMASessionsCleaner.h"
#import "AMAReportRequestModel.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAReachability.h"
#import "AMAReporterStoragesContainer.h"

@interface AMADispatcher (Test) <AMAReportsControllerDelegate>

@property (nonatomic, assign) BOOL inProgress;

@end

SPEC_BEGIN(AMADispatcherTests)

describe(@"AMADispatcher", ^{

    NSString *const apiKey = @"APIKEY";
    NSArray *events = @[ [AMAEvent nullMock] ];
    NSArray *eventBatches = @[ [AMAReportEventsBatch nullMock] ];

    AMAReportRequestModel *__block reportRequestModel = nil;
    NSArray *__block requestModels = nil;

    AMAMetricaConfiguration *__block configuration = nil;
    id<AMACancelableExecuting> __block executor = nil;
    AMAReportsController *__block reportsController = nil;
    AMAReportRequestProvider *__block provider = nil;
    AMASessionsCleaner *__block cleaner = nil;
    AMAIncrementableValueStorageMock *__block requestIdentifierStorage = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMAReporterStorage *__block reporterStorage = nil;
    AMADataSendingRestrictionController *__block restrictionController = nil;
    AMADispatcher *__block dispatcher = nil;

    id<AMADispatcherDelegate> __block delegate = nil;

    beforeEach(^{
        reportRequestModel = [AMAReportRequestModel nullMock];
        [reportRequestModel stub:@selector(events) andReturn:events];
        [reportRequestModel stub:@selector(apiKey) andReturn:apiKey];
        [reportRequestModel stub:@selector(eventsBatches) andReturn:eventBatches];
        requestModels = @[ reportRequestModel ];

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configuration = [AMAMetricaConfiguration sharedInstance];
        [configuration.startup stub:@selector(reportHosts) andReturn:@[@"host"]];
        [configuration.persistent stub:@selector(deviceID) andReturn:@"DeviceID"];
        [configuration.persistent stub:@selector(checkedInitialAttribution) andReturn:theValue(YES)];

        [AMAReporterStoragesContainer stub:@selector(sharedInstance) andReturn:[AMAReporterStoragesContainer nullMock]];
        
        executor = [[AMACurrentQueueExecutor alloc] init];

        reportsController = [AMAReportsController nullMock];

        provider = [AMAReportRequestProvider nullMock];
        [provider stub:@selector(requestModels) andReturn:requestModels];

        cleaner = [AMASessionsCleaner nullMock];

        restrictionController = [AMADataSendingRestrictionController nullMock];
        [restrictionController stub:@selector(shouldReportToApiKey:) andReturn:theValue(YES)];
        [AMADataSendingRestrictionController stub:@selector(sharedInstance) andReturn:restrictionController];

        requestIdentifierStorage = [[AMAIncrementableValueStorageMock alloc] init];
        requestIdentifierStorage.currentMockValue = @1;

        stateStorage = [AMAReporterStateStorage nullMock];
        [stateStorage stub:@selector(requestIDStorage) andReturn:requestIdentifierStorage];

        reporterStorage = [AMAReporterStorage nullMock];
        [reporterStorage stub:@selector(apiKey) andReturn:apiKey];
        [reporterStorage stub:@selector(stateStorage) andReturn:stateStorage];
        [reporterStorage stub:@selector(reportRequestProvider) andReturn:provider];
        [reporterStorage stub:@selector(sessionsCleaner) andReturn:cleaner];

        dispatcher = [[AMADispatcher alloc] initWithReporterStorage:reporterStorage
                                                               main:YES
                                                           executor:executor
                                                  reportsController:reportsController];

        delegate = [KWMock nullMockForProtocol:@protocol(AMADispatcherDelegate)];
        dispatcher.delegate = delegate;
    });

    context(@"Active", ^{

        it(@"Should report", ^{
            [[reportsController should] receive:@selector(reportRequestModelsFromArray:) withArguments:requestModels];
            [dispatcher performReport];
        });

        context(@"No report hosts", ^{
            
            beforeEach(^{
                [configuration.startup stub:@selector(reportHosts) andReturn:@[]];
            });

            it(@"Should not report", ^{
                [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                [dispatcher performReport];
            });

            it(@"Should call delegate", ^{
                NSError *expectedError = [NSError errorWithDomain:kAMADispatcherErrorDomain
                                                             code:AMADispatcherReportErrorNoHosts
                                                         userInfo:@{ kAMADispatcherErrorApiKeyUserInfoKey: apiKey }];
                [[(id)delegate should] receive:@selector(dispatcher:didFailToReportWithError:)
                                 withArguments:dispatcher, expectedError];
                [dispatcher performReport];
            });

        });

        context(@"No DeviceId", ^{

            beforeEach(^{
                [configuration.persistent stub:@selector(deviceID) andReturn:nil];
            });

            it(@"Should not report", ^{
                [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                [dispatcher performReport];
            });

            it(@"Should call delegate", ^{
                NSError *expectedError = [NSError errorWithDomain:kAMADispatcherErrorDomain
                                                             code:AMADispatcherReportErrorNoDeviceId
                                                         userInfo:@{ kAMADispatcherErrorApiKeyUserInfoKey: apiKey }];
                [[(id)delegate should] receive:@selector(dispatcher:didFailToReportWithError:)
                                 withArguments:dispatcher, expectedError];
                [dispatcher performReport];
            });

        });

        context(@"No network", ^{

            AMAReachability *__block reachability = nil;

            beforeEach(^{
                reachability = [AMAReachability nullMock];
                [AMAReachability stub:@selector(sharedInstance) andReturn:reachability];
            });

            it(@"Should not perform report", ^{
                [reachability stub:@selector(isNetworkReachable) andReturn:theValue(NO)];
                [reachability stub:@selector(status) andReturn:theValue(AMAReachabilityStatusNotReachable)];
                [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                [dispatcher performReport];
            });

            context(@"Should perform report", ^{

                it(@"Should try to perform report if status if unknown", ^{
                    [reachability stub:@selector(isNetworkReachable) andReturn:theValue(NO)];
                    [reachability stub:@selector(status) andReturn:theValue(AMAReachabilityStatusUnknown)];
                    [[reportsController should] receive:@selector(reportRequestModelsFromArray:)];
                    [dispatcher performReport];
                });

                it(@"Should perform report if status if network is reachable", ^{
                    [reachability stub:@selector(isNetworkReachable) andReturn:theValue(YES)];
                    [[reportsController should] receive:@selector(reportRequestModelsFromArray:)];
                    [dispatcher performReport];
                });
            });

        });

        context(@"No report requests", ^{

            beforeEach(^{
                [provider stub:@selector(requestModels) andReturn:@[]];
            });

            it(@"Should not report", ^{
                [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                [dispatcher performReport];
            });

            it(@"Should not call delegate", ^{
                [[(id)delegate shouldNot] receive:@selector(dispatcher:didFailToReportWithError:)];
                [dispatcher performReport];
            });

        });

        context(@"Restricted", ^{

            beforeEach(^{
                [restrictionController stub:@selector(shouldReportToApiKey:) andReturn:theValue(NO)];
            });

            it(@"Should call restriction controller with proper apiKey", ^{
                [[restrictionController should] receive:@selector(shouldReportToApiKey:) withArguments:apiKey];
                [dispatcher performReport];
            });

            it(@"Should not report", ^{
                [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                [dispatcher performReport];
            });

            it(@"Should call delegate", ^{
                NSError *expectedError = [NSError errorWithDomain:kAMADispatcherErrorDomain
                                                             code:AMADispatcherReportErrorDataSendingForbidden
                                                         userInfo:@{ kAMADispatcherErrorApiKeyUserInfoKey: apiKey }];
                [[(id)delegate should] receive:@selector(dispatcher:didFailToReportWithError:)
                                 withArguments:dispatcher, expectedError];
                [dispatcher performReport];
            });

        });

        context(@"Attribution model was not checked", ^{
            beforeEach(^{
                [configuration.persistent stub:@selector(checkedInitialAttribution) andReturn:theValue(NO)];
            });
            context(@"Not main", ^{
                beforeEach(^{
                    dispatcher = [[AMADispatcher alloc] initWithReporterStorage:reporterStorage
                                                                           main:NO
                                                                       executor:executor
                                                              reportsController:reportsController];

                    dispatcher.delegate = delegate;
                });
                it(@"Should report", ^{
                    [[reportsController should] receive:@selector(reportRequestModelsFromArray:)];
                    [dispatcher performReport];
                });
                it(@"Should not call delegate", ^{
                    [[(id)delegate shouldNot] receive:@selector(dispatcher:didFailToReportWithError:)];
                    [dispatcher performReport];
                });
            });
            context(@"Main", ^{
                beforeEach(^{
                    dispatcher = [[AMADispatcher alloc] initWithReporterStorage:reporterStorage
                                                                           main:YES
                                                                       executor:executor
                                                              reportsController:reportsController];

                    dispatcher.delegate = delegate;
                });
                it(@"Should not report", ^{
                    [[reportsController shouldNot] receive:@selector(reportRequestModelsFromArray:)];
                    [dispatcher performReport];
                });
                it(@"Should call delegate", ^{
                    [[(id)delegate should] receive:@selector(dispatcher:didFailToReportWithError:) withArguments:dispatcher, kw_any()];
                    [dispatcher performReport];
                });
            });
        });

    });

    context(@"Canceling pending", ^{

        it(@"Should cancel pending requests", ^{
            [[reportsController should] receive:@selector(cancelPendingRequests)];
            [dispatcher cancelPending];
        });
    });

    context(@"Reports Controller Response", ^{

        context(@"Report controller next request identifier", ^{
            
            it(@"Should return requestIDStorage string", ^{
                [[[dispatcher reportsControllerNextRequestIdentifier] should]
                    equal:requestIdentifierStorage.currentMockValue.stringValue];
            });
        });

        context(@"Report controller did report request", ^{

            it(@"Should purge events", ^{
                [[cleaner should] receive:@selector(purgeSessionWithRequestModel:reason:)
                            withArguments:reportRequestModel, theValue(AMAEventsCleanupReasonTypeSuccessfulReport)];
                [dispatcher reportsController:reportsController didReportRequest:reportRequestModel];
            });
            it(@"Should increment request id", ^{
                [[requestIdentifierStorage should] receive:@selector(nextInStorage:rollback:error:)];
                [dispatcher reportsController:reportsController didReportRequest:reportRequestModel];
            });
        });

        context(@"Reports controller did finish with success", ^{

            it(@"Should call delegate", ^{
                [[(id)delegate should] receive:@selector(dispatcherDidPerformReport:) withArguments:dispatcher];
                [dispatcher reportsControllerDidFinishWithSuccess:reportsController];
            });
            
        });

        context(@"Report controller did fail reporting request", ^{

            NSError *__block error = nil;

            context(@"Call delegate", ^{

                NSNumber *__block statusCode = nil;
                NSError *__block receivedError = nil;

                beforeAll(^{
                    statusCode = @400;
                    error = [NSError errorWithDomain:kAMAReportsControllerErrorDomain
                                                code:AMAReportsControllerErrorBadRequest
                                            userInfo:nil];

                    KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(dispatcher:didFailToReportWithError:)
                                                              atIndex:1];
                    [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    receivedError = spy.argument;
                });

                it(@"Should call with non-nil error", ^{
                    [[receivedError should] beNonNil];
                });

                it(@"Should contain proper domain in error", ^{
                    [[receivedError.domain should] equal:kAMADispatcherErrorDomain];
                });

                it(@"Should contain proper code in error", ^{
                    [[theValue(receivedError.code) should] equal:theValue(AMADispatcherReportErrorNetwork)];
                });

            });

            context(@"Error types", ^{

                context(@"Bad request", ^{
                    beforeEach(^{
                        error = [NSError errorWithDomain:kAMAReportsControllerErrorDomain
                                                    code:AMAReportsControllerErrorBadRequest
                                                userInfo:nil];
                    });
                    it(@"Should purge events", ^{
                        [[cleaner should] receive:@selector(purgeSessionWithRequestModel:reason:)
                                    withArguments:reportRequestModel, theValue(AMAEventsCleanupReasonTypeBadRequest)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });
                    it(@"Should increment request id", ^{
                        [[requestIdentifierStorage should] receive:@selector(nextInStorage:rollback:error:)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });
                });

                context(@"Entity Too Large", ^{
                    beforeEach(^{
                        error = [NSError errorWithDomain:kAMAReportsControllerErrorDomain
                                                    code:AMAReportsControllerErrorRequestEntityTooLarge
                                                userInfo:nil];
                    });
                    it(@"Should purge events", ^{
                        [[cleaner should] receive:@selector(purgeSessionWithRequestModel:reason:)
                                    withArguments:reportRequestModel, theValue(AMAEventsCleanupReasonTypeEntityTooLarge)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });
                    it(@"Should increment request id", ^{
                        [[requestIdentifierStorage should] receive:@selector(nextInStorage:rollback:error:)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });
                });

                context(@"Other", ^{

                    beforeEach(^{
                        error = [NSError errorWithDomain:kAMAReportsControllerErrorDomain
                                                    code:AMAReportsControllerErrorOther
                                                userInfo:nil];
                    });

                    it(@"Should not purge events", ^{
                        [[cleaner shouldNot] receive:@selector(purgeSessionWithEventsBatches:reason:)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });

                    it(@"Should not increment request identifier", ^{
                        [[requestIdentifierStorage shouldNot] receive:@selector(nextInStorage:rollback:error:)];
                        [dispatcher reportsController:reportsController didFailRequest:reportRequestModel withError:error];
                    });

                });

            });

        });

    });
    
    it(@"Should conform to AMAReportsControllerDelegate", ^{
        [[dispatcher should] conformToProtocol:@protocol(AMAReportsControllerDelegate)];
    });
});

SPEC_END
