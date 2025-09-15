
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAReportsController.h"
#import "AMAReportRequestMock.h"
#import "AMAHostProviderMock.h"
#import "AMAInternalEventsReporter.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAReportPayloadProvider.h"
#import "AMAReportRequestModel.h"
#import "AMAReportPayload.h"
#import "AMAEvent.h"
#import "AMAReportEventsBatch.h"
#import "AMASession.h"
#import "AMATimeoutRequestsController.h"
#import "AMAReportHostProviderMock.h"
#import "AMAReportRequestFactory.h"
#import "AMAProxyReportsController.h"

SPEC_BEGIN(AMAReportsControllerTests)

NSString *const apiKey = @"API_KEY";
NSString *const attributionID = @"1";
NSString *const requestIdentifier = @"23";
NSString *const firstHost = @"https://appmetrica.com/";
NSString *const secondHost = @"https://appmetri.ca/";
NSString *const thirdHost = @"https://appmetrica.io";
NSArray<NSString *> *const hosts = @[ firstHost, secondHost, thirdHost ];
NSString *const firstTrackingHost = @"https://tracking.appmetrica.com";
NSString *const secondTrackingHost = @"https://tracking.appmetri.ca";
NSString *const thirdTrackingHost = @"https://tracking.appmetrica.io";
NSArray *const additionalAPIKeys = @[@"additional_api_key_1", @"additional_api_key_2"];
NSArray<NSString *> *const trackingHosts = @[firstTrackingHost, secondTrackingHost, thirdTrackingHost];
NSData *const responseData = [@"BODY" dataUsingEncoding:NSUTF8StringEncoding];

AMAReportPayload *__block payload = nil;
AMAReportPayload *__block secondPayload = nil;
AMAReportRequestModel *__block firstReportRequestModel = nil;
AMAReportRequestModel *__block secondReportRequestModel = nil;
AMAReportRequest *__block reportRequest = nil;
AMAReportRequest *__block secondReportRequest = nil;
NSArray *__block reportRequestModels = nil;
AMAReportEventsBatch __block *firstEventBatch = nil;
AMAReportEventsBatch __block *secondEventBatch = nil;

AMAInternalEventsReporter *__block internalEventsReporter = nil;
AMAHostProviderMock *__block hostProvider = nil;
AMAHostProviderMock *__block trackingHostProvider = nil;
AMAReportResponseParser *__block responseParser = nil;
AMAHTTPRequestsFactoryMock *__block httpRequestsFactory = nil;
AMAReportPayloadProvider *__block payloadProvider = nil;
NSObject<AMAReportsControllerDelegate> *__block delegate = nil;
id<AMAReportsControlling> __block controller = nil;
AMATimeoutRequestsController *__block timeoutController = nil;
AMARegularReportRequestFactory *__block requestFactory = nil;

void (^beforeEachReporter)() = ^{
    AMAApplicationState *appstate = [AMAApplicationState new];
    [AMAApplicationStateManager stub:@selector(applicationState) andReturn:appstate];
    [AMAApplicationStateManager stub:@selector(stateWithFilledEmptyValues:) andReturn:appstate];
    
    NSArray *events = @[
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
    ];
    
    firstEventBatch =
        [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                       appEnvironment:@{ @"first": @1 }
                                               events:[events subarrayWithRange:NSMakeRange(0, 1)]];
    secondEventBatch =
        [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                       appEnvironment:@{ @"second": @2 }
                                               events:[events subarrayWithRange:NSMakeRange(1, 4)]];
    firstReportRequestModel = [AMAReportRequestModel reportRequestModelWithApiKey:apiKey
                                                                    attributionID:attributionID
                                                                   appEnvironment:@{}
                                                                         appState:appstate
                                                                 inMemoryDatabase:NO
                                                                additionalAPIKeys:additionalAPIKeys
                                                                    eventsBatches:@[ firstEventBatch, secondEventBatch ]];

    payload = [[AMAReportPayload alloc] initWithReportModel:firstReportRequestModel data:[NSData data]];
    reportRequest = [AMAReportRequestMock reportRequestWithPayload:payload
                                                 requestIdentifier:requestIdentifier
                                          requestParametersOptions:AMARequestParametersDefault];
    payloadProvider = [AMAReportPayloadProvider nullMock];
    [payloadProvider stub:@selector(generatePayloadWithRequestModel:error:) andReturn:payload];
    reportRequestModels = @[ firstReportRequestModel ];

    secondReportRequestModel = [[AMAReportRequestModel alloc] init];
    secondPayload = [[AMAReportPayload alloc] initWithReportModel:secondReportRequestModel data:[NSData data]];
    secondReportRequest = [AMAReportRequestMock reportRequestWithPayload:secondPayload
                                                       requestIdentifier:requestIdentifier
                                                requestParametersOptions:AMARequestParametersDefault];

    delegate = [KWMock nullMockForProtocol:@protocol(AMAReportsControllerDelegate)];
    [delegate stub:@selector(reportsControllerNextRequestIdentifierForController:) andReturn:requestIdentifier];

    internalEventsReporter = [AMAInternalEventsReporter nullMock];
    [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];

    responseParser = [AMAReportResponseParser nullMock];
    AMAReportResponse *response = [[AMAReportResponse alloc] initWithStatus:AMAReportResponseStatusAccepted];
    [responseParser stub:@selector(responseForData:) andReturn:response withArguments:responseData];

    AMACurrentQueueExecutor *executor = [[AMACurrentQueueExecutor alloc] init];
    hostProvider = [[AMAHostProviderMock alloc] initWithItems:hosts];
    httpRequestsFactory = [[AMAHTTPRequestsFactoryMock alloc] init];

    timeoutController = [AMATimeoutRequestsController nullMock];
    [timeoutController stub:@selector(isAllowed) andReturn:theValue(YES)];
    
    requestFactory = [[AMARegularReportRequestFactory alloc] init];
    
    controller = [[AMAReportsController alloc] initWithExecutor:executor
                                                   hostProvider:hostProvider
                                            httpRequestsFactory:httpRequestsFactory
                                                 responseParser:responseParser
                                                payloadProvider:payloadProvider
                                      timeoutRequestsController:timeoutController
                                           reportRequestFactory:requestFactory];
    controller.delegate = delegate;
};

void (^beforeEachProxyReporter)() = ^{
    AMAApplicationState *appstate = [AMAApplicationState new];
    [AMAApplicationStateManager stub:@selector(applicationState) andReturn:appstate];
    [AMAApplicationStateManager stub:@selector(stateWithFilledEmptyValues:) andReturn:appstate];
    
    NSMutableArray *events = @[
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
        [AMAEvent mock],
    ].mutableCopy;
    
    for (AMAEvent *event in events) {
        [event stub:@selector(type) andReturn:theValue(AMAEventTypeClient)];
    }
    
    AMAEvent *trackingEvent = [AMAEvent mock];
    [trackingEvent stub:@selector(type) andReturn:theValue(AMAEventTypeApplePrivacy)];
    [events addObject:trackingEvent];

    firstEventBatch =
        [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                       appEnvironment:@{ @"first": @1 }
                                               events:[events subarrayWithRange:NSMakeRange(0, 1)]];
    secondEventBatch =
        [[AMAReportEventsBatch alloc] initWithSession:[AMASession mock]
                                       appEnvironment:@{ @"second": @2 }
                                               events:[events subarrayWithRange:NSMakeRange(1, 4)]];
    firstReportRequestModel = [AMAReportRequestModel reportRequestModelWithApiKey:apiKey
                                                                    attributionID:attributionID
                                                                   appEnvironment:@{}
                                                                         appState:appstate
                                                                 inMemoryDatabase:NO
                                                                additionalAPIKeys:additionalAPIKeys
                                                                    eventsBatches:@[ firstEventBatch, secondEventBatch ]];

    payload = [[AMAReportPayload alloc] initWithReportModel:firstReportRequestModel data:[NSData data]];
    reportRequest = [AMAReportRequestMock reportRequestWithPayload:payload
                                                 requestIdentifier:requestIdentifier
                                          requestParametersOptions:AMARequestParametersDefault];
    payloadProvider = [AMAReportPayloadProvider nullMock];
    [payloadProvider stub:@selector(generatePayloadWithRequestModel:error:) andReturn:payload];
    reportRequestModels = @[ firstReportRequestModel ];

    secondReportRequestModel = [[AMAReportRequestModel alloc] init];
    secondPayload = [[AMAReportPayload alloc] initWithReportModel:secondReportRequestModel data:[NSData data]];
    secondReportRequest = [AMAReportRequestMock reportRequestWithPayload:secondPayload
                                                       requestIdentifier:requestIdentifier
                                                requestParametersOptions:AMARequestParametersDefault];

    delegate = [KWMock nullMockForProtocol:@protocol(AMAReportsControllerDelegate)];
    [delegate stub:@selector(reportsControllerNextRequestIdentifierForController:) andReturn:requestIdentifier];

    internalEventsReporter = [AMAInternalEventsReporter nullMock];
    [AMAAppMetrica stub:@selector(sharedInternalEventsReporter) andReturn:internalEventsReporter];

    responseParser = [AMAReportResponseParser nullMock];
    AMAReportResponse *response = [[AMAReportResponse alloc] initWithStatus:AMAReportResponseStatusAccepted];
    [responseParser stub:@selector(responseForData:) andReturn:response withArguments:responseData];

    AMACurrentQueueExecutor *executor = [[AMACurrentQueueExecutor alloc] init];
    hostProvider = [[AMAHostProviderMock alloc] initWithItems:hosts];
    httpRequestsFactory = [[AMAHTTPRequestsFactoryMock alloc] init];
    
    trackingHostProvider = [[AMAHostProviderMock alloc] initWithItems:trackingHosts];

    timeoutController = [AMATimeoutRequestsController nullMock];
    [timeoutController stub:@selector(isAllowed) andReturn:theValue(YES)];
    
    requestFactory = [[AMARegularReportRequestFactory alloc] init];
    
    AMAReportsController *regularController = [[AMAReportsController alloc] initWithExecutor:executor
                                                                                hostProvider:hostProvider
                                                                         httpRequestsFactory:httpRequestsFactory
                                                                              responseParser:responseParser
                                                                             payloadProvider:payloadProvider
                                                                   timeoutRequestsController:timeoutController
                                                                        reportRequestFactory:requestFactory];
    
    AMAReportsController *trackingController = [[AMAReportsController alloc] initWithExecutor:executor
                                                                                 hostProvider:trackingHostProvider
                                                                          httpRequestsFactory:httpRequestsFactory
                                                                               responseParser:responseParser
                                                                              payloadProvider:payloadProvider
                                                                    timeoutRequestsController:timeoutController
                                                                         reportRequestFactory:requestFactory];
    
    controller = [[AMAProxyReportsController alloc] initWithExecutor:executor
                                            regularReportsController:regularController
                                           trackingReportsController:trackingController];
    controller.delegate = delegate;
};

void (^testBlock)() = ^{

    context(@"The the first host is correct", ^{

        beforeEach(^{
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                              forHost:firstHost];
        });
        
        it(@"Should ask timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(isAllowed)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should update empty fields of app state", ^{
            [[AMAApplicationStateManager should] receive:@selector(stateWithFilledEmptyValues:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not update all fields of app state", ^{
            [[AMAApplicationStateManager shouldNot] receive:@selector(applicationState)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about report sending success", ^{
            [[(id)delegate should] receive:@selector(reportsController:didReportRequest:)
                             withArguments:controller, firstReportRequestModel];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about overall success", ^{
            [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                             withArguments:controller];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about error", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should not request the second host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });
    
        context(@"200 and AMAReportResponseStatusUnknown", ^{

            beforeEach(^{
                AMAReportResponse *response =
                    [[AMAReportResponse alloc] initWithStatus:AMAReportResponseStatusUnknown];
                [responseParser stub:@selector(responseForData:) andReturn:response withArguments:responseData];
            });

            it(@"Should not report of failure to timeout controller", ^{
                [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should report of success to timeout controller 3 times", ^{
                [[timeoutController should] receive:@selector(reportOfSuccess) withCount:3];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should notify delegate about unkown json status", ^{
                KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                          atIndex:2];
                [controller reportRequestModelsFromArray:reportRequestModels];
                NSError *receivedError = spy.argument;
                [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
                [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorJsonStatusUnknown)];
            });
        });
        
        context(@"Timeout reached", ^{

            beforeEach(^{
                [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
            });

            it(@"Should notify delegate about timeout error", ^{
                KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                          atIndex:2];
                [controller reportRequestModelsFromArray:reportRequestModels];
                NSError *receivedError = spy.argument;
                [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
                [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorTimeout)];
            });

            it(@"Should not iterate host provider", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
            });
        });
    });

    context(@"The the first host responds 413 and respond could be split", ^{

        beforeEach(^{

            BOOL __block isFirstRequest = YES;

            [httpRequestsFactory stubHost:firstHost withBlock:^AMAHTTPRequestResponseStub *(NSURL *url, NSDictionary *headers) {
                if (isFirstRequest) {
                    isFirstRequest = NO;
                    return [AMAHTTPRequestResponseStub successWithCode:413 data:nil];
                }
                else {
                    return [AMAHTTPRequestResponseStub successWithCode:200 data:responseData];
                }
            }];
        });

        it(@"Should ask timeout controller 3 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:3];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 3 times", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess) withCount:3];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Should reset host provider twice", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(2)];
        });

        it(@"Should update empty fields of app state", ^{
            [[AMAApplicationStateManager should] receive:@selector(stateWithFilledEmptyValues:) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not update all fields of app state", ^{
            [[AMAApplicationStateManager shouldNot] receive:@selector(applicationState) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about report sending success ", ^{
            [[(id)delegate should] receive:@selector(reportsController:didReportRequest:)
                                 withCount:2
                                 arguments:controller, firstReportRequestModel];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about overall success", ^{
            [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                             withArguments:controller];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about error", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should request the first host 3 times", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(3)];
        });

        it(@"Should not request the second host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"The the first host responds 413 and respond could not be split", ^{

        beforeEach(^{
            [payloadProvider stub:@selector(generatePayloadWithRequestModel:error:) withBlock:^id(NSArray *params) {
                return [[AMAReportPayload alloc] initWithReportModel:params.firstObject data:[NSData data]];
            }];
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:413 data:nil] forHost:firstHost];
        });

        it(@"Should ask timeout controller 3 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:3];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 3 times", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess) withCount:3];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should not notify delegate about report sending success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didReportRequest:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about overall success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsControllerDidFinishWithSuccess:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about Too Big Request error", ^{
            KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                      atIndex:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
            NSError *receivedError = spy.argument;
            [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
            [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorRequestEntityTooLarge)];
        });

        it(@"Should request the first host 3 times", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(3)];
        });

        it(@"Should not request the second host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"The the first host doesn't return valid body but the the second does", ^{

        beforeEach(^{
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:nil]
                              forHost:firstHost];

            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                              forHost:secondHost];
        });

        it(@"Should ask timeout controller 2 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 2 times", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(1)];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should notify delegate about report sending success", ^{
            [[(id)delegate should] receive:@selector(reportsController:didReportRequest:)
                             withArguments:controller, firstReportRequestModel];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about overall success", ^{
            [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                             withArguments:controller];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about error", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should request the second host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(1)];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"The the first host responds 400 and the the second is correct", ^{

        beforeEach(^{
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:400 data:nil]
                              forHost:firstHost];

            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                              forHost:secondHost];
        });

        it(@"Should ask timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(isAllowed)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should not notify delegate about report sending success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didReportRequest:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about overall success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsControllerDidFinishWithSuccess:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about bad request error", ^{
            KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                      atIndex:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
            NSError *receivedError = spy.argument;
            [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
            [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorBadRequest)];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should not request the second host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"Reset request header", ^{
        NSString *__block firstHostTimestamp = nil;
        NSString *__block secondHostTimestamp = nil;

        beforeEach(^{
            [httpRequestsFactory stubHost:firstHost
                                withBlock:^AMAHTTPRequestResponseStub *(NSURL *url, NSDictionary *headers) {
                firstHostTimestamp = headers[@"Send-Timestamp"];
                [NSThread sleepForTimeInterval:2];
                return [AMAHTTPRequestResponseStub successWithCode:500 data:nil];
            }];

            [httpRequestsFactory stubHost:secondHost
                                withBlock:^AMAHTTPRequestResponseStub *(NSURL *url, NSDictionary *headers) {
                secondHostTimestamp = headers[@"Send-Timestamp"];
                return [AMAHTTPRequestResponseStub successWithCode:200 data:responseData];
            }];
        });

        it(@"Should reset timestamp on request retry", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[firstHostTimestamp shouldNot] equal:secondHostTimestamp];
        });
    });

    context(@"The the first host responds 500 and the second is correct", ^{

        beforeEach(^{
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil] forHost:firstHost];
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                              forHost:secondHost];
        });

        it(@"Should ask timeout controller 2 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(1)];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should notify delegate about report sending success", ^{
            [[(id)delegate should] receive:@selector(reportsController:didReportRequest:)
                             withArguments:controller, firstReportRequestModel];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about overall success", ^{
            [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                             withArguments:controller];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about error", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should request the second host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(1)];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"The the first host responds 500 and the second is correct", ^{

        beforeEach(^{
            NSError *networkError = [NSError errorWithDomain:NSURLErrorDomain
                                                        code:NSURLErrorNotConnectedToInternet
                                                    userInfo:nil];
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub failureWithCode:500 error:networkError]
                              forHost:firstHost];
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                              forHost:secondHost];
        });

        it(@"Should ask timeout controller 2 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of success to timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(reportOfSuccess)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of failure to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(1)];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should notify delegate about report sending success", ^{
            [[(id)delegate should] receive:@selector(reportsController:didReportRequest:)
                             withArguments:controller, firstReportRequestModel];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about overall success", ^{
            [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                             withArguments:controller];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about error", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should request the second host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(1)];
        });

        it(@"Should not request third host", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
        });

    });

    context(@"All hosts are 500", ^{

        beforeEach(^{
            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil]
                              forHost:firstHost];

            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil]
                              forHost:secondHost];

            [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil]
                              forHost:thirdHost];
        });

        it(@"Should ask timeout controller 3 times", ^{
            [[timeoutController should] receive:@selector(isAllowed) withCount:3];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not report of success to timeout controller", ^{
            [[timeoutController shouldNot] receive:@selector(reportOfSuccess)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should report of failure to timeout controller 1 time", ^{
            [[timeoutController should] receive:@selector(reportOfFailure)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should iterate host provider", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(3)];
        });

        it(@"Should reset host provider once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
        });

        it(@"Should not notify delegate about report sending success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsController:didReportRequest:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should not notify delegate about overall success", ^{
            [[(id)delegate shouldNot] receive:@selector(reportsControllerDidFinishWithSuccess:)];
            [controller reportRequestModelsFromArray:reportRequestModels];
        });

        it(@"Should notify delegate about unknown error", ^{
            KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                      atIndex:2];
            [controller reportRequestModelsFromArray:reportRequestModels];
            NSError *receivedError = spy.argument;
            [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
            [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorOther)];
        });

        it(@"Should request the first host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
        });

        it(@"Should request the second host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(1)];
        });

        it(@"Should request third host once", ^{
            [controller reportRequestModelsFromArray:reportRequestModels];
            [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] equal:theValue(1)];
        });

        context(@"Timeout reached", ^{

            beforeEach(^{
                [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil]
                                  forHost:firstHost];

                [httpRequestsFactory stubHost:secondHost withBlock:^(NSURL *url, NSDictionary *headers) {
                    [timeoutController stub:@selector(isAllowed) andReturn:theValue(NO)];
                    return [AMAHTTPRequestResponseStub successWithCode:500 data:responseData];
                }];

                [httpRequestsFactory stubHost:thirdHost withBlock:^(NSURL *url, NSDictionary *headers) {
                    return [AMAHTTPRequestResponseStub successWithCode:500 data:responseData];
                }];
            });

            it(@"Should iterate host provider twise", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(2)];
            });

            it(@"Should ask timeout controller 3 times", ^{
                [[timeoutController should] receive:@selector(isAllowed) withCount:3];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should reset host provider", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
            });

            it(@"Should notify delegate about timeout error", ^{
                KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                          atIndex:2];
                [controller reportRequestModelsFromArray:reportRequestModels];
                NSError *receivedError = spy.argument;
                [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
                [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorTimeout)];
            });

            it(@"Should request the first host once", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
            });

            it(@"Should not request the second host", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(1)];
            });

            it(@"Should not request third host", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
            });
        });

    });

    context(@"Multiple requests", ^{

        beforeEach(^{
            [AMAReportRequest stub:@selector(reportRequestWithPayload:requestIdentifier:requestParametersOptions:) withBlock:^id(NSArray *params) {
                AMAReportPayload *payload = params[0];
                if ([payload.model isEqual:firstReportRequestModel]) {
                    return reportRequest;
                }
                else {
                    return secondReportRequest;
                }
            }];
            [payloadProvider stub:@selector(generatePayloadWithRequestModel:error:) withBlock:^id(NSArray *params) {
                if ([params[0] isEqual:firstReportRequestModel]) {
                    return payload;
                }
                else {
                    return secondPayload;
                }
            }];
            reportRequestModels = @[ firstReportRequestModel, secondReportRequestModel ];
        });

        context(@"The the first host responds 400 and the second is correct", ^{

            beforeEach(^{
                [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:400 data:nil]
                                  forHost:firstHost];

                [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                                  forHost:secondHost];
            });

            it(@"Should ask timeout controller 1 time", ^{
                [[timeoutController should] receive:@selector(isAllowed)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should report of success to timeout controller 1 time", ^{
                [[timeoutController should] receive:@selector(reportOfSuccess)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should not report of failure to timeout controller", ^{
                [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should not iterate host provider", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitNext) should] beZero];
            });

            it(@"Should reset host provider once", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
            });

            it(@"Should not notify delegate about report sending success", ^{
                [[(id)delegate shouldNot] receive:@selector(reportsController:didReportRequest:)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should not notify delegate about overall success", ^{
                [[(id)delegate shouldNot] receive:@selector(reportsControllerDidFinishWithSuccess:)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should notify delegate about error once", ^{
                [[(id)delegate should] receive:@selector(reportsController:didFailRequest:withError:) withCount:1];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should notify delegate about bad request error", ^{
                KWCaptureSpy *spy = [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:)
                                                          atIndex:2];
                [controller reportRequestModelsFromArray:reportRequestModels];
                NSError *receivedError = spy.argument;
                [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
                [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorBadRequest)];
            });

            it(@"Should request the first host once", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
            });

            it(@"Should not request the second host", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
            });

            it(@"Should not request third host", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
            });

        });

        context(@"The the first host responds 500 and the second is correct", ^{

            beforeEach(^{
                [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:500 data:nil]
                                  forHost:firstHost];

                [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                                  forHost:secondHost];
            });

            it(@"Should ask timeout controller 4 times", ^{
                [[timeoutController should] receive:@selector(isAllowed) withCount:4];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should report of success to timeout controller 2 times", ^{
                [[timeoutController should] receive:@selector(reportOfSuccess) withCount:2];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should not report of failure to timeout controller", ^{
                [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should iterate host provider", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(2)];
            });

            it(@"Should reset host provider 2 times", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(2)];
            });

            it(@"Should notify delegate about report sending success for every report request", ^{
                NSMutableArray *returnedRequestModels = [NSMutableArray array];
                [(id)delegate stub:@selector(reportsController:didReportRequest:) withBlock:^id(NSArray *params) {
                    [returnedRequestModels addObject:params[1]];
                    return nil;
                }];
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[[returnedRequestModels copy] should] equal: @[ firstReportRequestModel, secondReportRequestModel ]];
            });

            it(@"Should notify delegate about overall success once", ^{
                [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                                     withCount:1
                                     arguments:controller];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should not notify delegate about error", ^{
                [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
                [controller reportRequestModelsFromArray:reportRequestModels];
            });

            it(@"Should request the first host 2 times", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(2)];
            });

            it(@"Should request the second host 2 times", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] equal:theValue(2)];
            });

            it(@"Should not request third host", ^{
                [controller reportRequestModelsFromArray:reportRequestModels];
                [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
            });

        });

        context(@"Cancel during the first request", ^{

            context(@"The the first request is successful", ^{

                beforeEach(^{
                    [httpRequestsFactory stubHost:firstHost withBlock:^(NSURL *url, NSDictionary *headers) {
                        [controller cancelPendingRequests];
                        return [AMAHTTPRequestResponseStub successWithCode:200 data:responseData];
                    }];
                });

                it(@"Should ask timeout controller 1 time", ^{
                    [[timeoutController should] receive:@selector(isAllowed)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should report of success to timeout controller 1 time", ^{
                    [[timeoutController should] receive:@selector(reportOfSuccess)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not report of failure to timeout controller", ^{
                    [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not iterate host provider", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(0)];
                });

                it(@"Should reset host provider", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
                });

                it(@"Should notify delegate about report sending the first request success", ^{
                    NSMutableArray *returnedRequestModels = [NSMutableArray array];
                    [(id)delegate stub:@selector(reportsController:didReportRequest:) withBlock:^id(NSArray *params) {
                        [returnedRequestModels addObject:params[1]];
                        return nil;
                    }];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[[returnedRequestModels copy] should] equal: @[ firstReportRequestModel ]];
                });

                it(@"Should notify delegate about overall success once", ^{
                    [[(id)delegate should] receive:@selector(reportsControllerDidFinishWithSuccess:)
                                         withCount:1
                                         arguments:controller];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not notify delegate about error", ^{
                    [[(id)delegate shouldNot] receive:@selector(reportsController:didFailRequest:withError:)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should request the first host once", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
                });

                it(@"Should not request the second host", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
                });

                it(@"Should not request third host", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
                });

            });

            context(@"The the second request is successful", ^{

                beforeEach(^{
                    [httpRequestsFactory stubHost:firstHost withBlock:^(NSURL *url, NSDictionary *headers) {
                        [controller cancelPendingRequests];
                        return [AMAHTTPRequestResponseStub successWithCode:500 data:nil];
                    }];

                    [httpRequestsFactory stub:[AMAHTTPRequestResponseStub successWithCode:200 data:responseData]
                                      forHost:secondHost];
                });

                it(@"Should ask timeout controller 1 time", ^{
                    [[timeoutController should] receive:@selector(isAllowed)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not report of success to timeout controller", ^{
                    [[timeoutController shouldNot] receive:@selector(reportOfSuccess)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not report of failure to timeout controller", ^{
                    [[timeoutController shouldNot] receive:@selector(reportOfFailure)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not iterate host provider", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue(hostProvider.numberOfTimesHitNext) should] equal:theValue(0)];
                });

                it(@"Should reset host provider", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue(hostProvider.numberOfTimesHitReset) should] equal:theValue(1)];
                });

                it(@"Should not notify delegate about report sending success", ^{
                    [[(id)delegate shouldNot] receive:@selector(reportsController:didReportRequest:)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should not notify delegate about overall success", ^{
                    [[(id)delegate shouldNot] receive:@selector(reportsControllerDidFinishWithSuccess:)];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                });

                it(@"Should notify delegate about unknown error", ^{
                    KWCaptureSpy *spy =
                        [(id)delegate captureArgument:@selector(reportsController:didFailRequest:withError:) atIndex:2];
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    NSError *receivedError = spy.argument;
                    [[receivedError.domain should] equal:kAMAReportsControllerErrorDomain];
                    [[theValue(receivedError.code) should] equal:theValue(AMAReportsControllerErrorOther)];
                });

                it(@"Should request the first host once", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:firstHost]) should] equal:theValue(1)];
                });

                it(@"Should not request the second host", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:secondHost]) should] beZero];
                });

                it(@"Should not request third host", ^{
                    [controller reportRequestModelsFromArray:reportRequestModels];
                    [[theValue([httpRequestsFactory countOfRequestsForHost:thirdHost]) should] beZero];
                });

            });

        });

    });
    
};

describe(@"AMAReportsControllerTests", ^{
    
    context(@"AMAReporterController", ^{
        beforeEach(beforeEachReporter);
        testBlock();
        
        it(@"Should conform to AMAHTTPRequestDelegate", ^{
            AMAReportsController *cntrl = (AMAReportsController*)controller;
            [[cntrl should] conformToProtocol:@protocol(AMAHTTPRequestDelegate)];
        });
        it(@"Should conform to AMAReportPayloadProviderDelegate", ^{
            AMAReportsController *cntrl = (AMAReportsController*)controller;
            [[cntrl should] conformToProtocol:@protocol(AMAReportPayloadProviderDelegate)];
        });
        
        context(@"Init", ^{
            it(@"Should set payload provider delegate with designed init", ^{
                id executor = [KWMock nullMockForProtocol:@protocol(AMAAsyncExecuting)];
                AMAReportPayloadProvider *payloadProvider = [[AMAReportPayloadProvider alloc] init];
                AMAReportsController *cntrl = [[AMAReportsController alloc] initWithExecutor:executor
                                                                                hostProvider:hostProvider
                                                                         httpRequestsFactory:httpRequestsFactory
                                                                              responseParser:responseParser
                                                                             payloadProvider:payloadProvider
                                                                   timeoutRequestsController:timeoutController
                                                                        reportRequestFactory:requestFactory];
                [[(NSObject *)payloadProvider.delegate should] equal:cntrl];
            });
            
            it(@"Should set payload provider delegate with convenience init", ^{
                id executor = [KWMock nullMockForProtocol:@protocol(AMAAsyncExecuting)];
                AMAReportPayloadProvider *payloadProvider = [AMAReportPayloadProvider stubbedNullMockForDefaultInit];
                [[payloadProvider should] receive:@selector(setDelegate:)];
                AMAReportsController *cntrl = [[AMAReportsController alloc] initWithExecutor:executor
                                                                   timeoutRequestsController:timeoutController
                                                                        reportRequestFactory:requestFactory];
            });
        });
    });
    
    describe(@"AMAProxyRepoterController", ^{
        beforeEach(beforeEachProxyReporter);
        testBlock();
    });
    
});


SPEC_END
