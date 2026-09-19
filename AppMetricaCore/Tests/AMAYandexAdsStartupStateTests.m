#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaNetwork/AppMetricaNetwork.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMAStartupController.h"
#import "AMAStartupRequest.h"
#import "AMAStartupResponse.h"
#import "AMAStartupResponseParser.h"
#import "AMAYandexAdsStartupStateProvider.h"
#import "AMAYandexAdsSDKDetector.h"
#import "AMASavedAppMetricaConfigRepository.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMAIdentifiersTestUtilities.h"
#import "AMAIdentifierProviderMock.h"
#import "AMAHostProviderMock.h"
#import "AMATimeoutRequestsController.h"
#import "AMAAttributionController.h"
#import "AMAAppStateManagerTestHelper.h"
#import "AMADefaultReportExecutionConditionChecker.h"

SPEC_BEGIN(AMAYandexAdsStartupStateTests)

describe(@"Startup Yandex Ads state snapshots", ^{
    AMAMetricaConfiguration *__block configuration;
    AMAYandexAdsStartupStateProvider *__block provider;
    AMAStartupResponseParser *__block parser;
    AMATimeoutRequestsController *__block timeout;
    AMAStartupController *__block controller;
    AMAAppStateManagerTestHelper *__block appState;
    NSMutableArray<AMAHTTPRequestor *> *__block requests;
    BOOL __block isYandexAdsOnly;

    AMAStartupController *(^makeController)(NSArray *) = ^(NSArray *hosts) {
        return [[AMAStartupController alloc]
            initWithExecutor:[[AMACurrentQueueExecutor alloc] init]
            hostProvider:[[AMAHostProviderMock alloc] initWithItems:hosts]
            timeoutRequestsController:timeout
            startupResponseParser:parser
            attributionController:[AMAAttributionController nullMock]
            metricaConfiguration:configuration
            stateProvider:provider];
    };
    void (^succeed)(AMAHTTPRequestor *) = ^(AMAHTTPRequestor *requestor) {
        AMAStartupResponse *parsed = [[AMAStartupResponse alloc] initWithStartupConfiguration:configuration.startup];
        [parsed stub:@selector(deviceIDHash) andReturn:configuration.deviceIDHash];
        [parser stub:@selector(startupResponseWithHTTPResponse:data:error:) andReturn:parsed];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
            initWithURL:[NSURL URLWithString:@"https://startup.test"] statusCode:200
            HTTPVersion:@"HTTP/1.1" headerFields:nil];
        [requestor.delegate httpRequestor:requestor didFinishWithData:[NSData data] response:response];
    };
    void (^failRequest)(AMAHTTPRequestor *) = ^(AMAHTTPRequestor *requestor) {
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];
        [requestor.delegate httpRequestor:requestor didFinishWithError:error response:nil];
    };

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfiguration];
        configuration = [AMAMetricaConfiguration sharedInstance];
        configuration.persistent.startupUpdatedAt = [NSDate date];
        [[AMAIdentifiersTestUtilities stubIdentifierProviderIfNeeded] fillRandom];
        appState = [[AMAAppStateManagerTestHelper alloc] init];
        [appState stubApplicationState];
        [AMAPlatformDescription stub:@selector(appID) andReturn:@"io.appmetrica.test"];
        requests = [NSMutableArray array];
        isYandexAdsOnly = NO;
        provider = [[AMAYandexAdsStartupStateProvider alloc]
            initWithRepository:[AMASavedAppMetricaConfigRepository nullMock]
            detector:[AMAYandexAdsSDKDetector nullMock]
            persistentConfiguration:configuration.persistent];
        [provider stub:@selector(isYandexAdsOnly) withBlock:^id(NSArray *arguments) { return theValue(isYandexAdsOnly); }];
        parser = [AMAStartupResponseParser nullMock];
        timeout = [AMATimeoutRequestsController nullMock];
        [timeout stub:@selector(isAllowed) andReturn:theValue(YES)];
        [AMAHTTPRequestor stub:@selector(requestorWithRequest:) withBlock:^id(NSArray *arguments) {
            AMAHTTPRequestor *requestor = [[AMAHTTPRequestor alloc] initWithRequest:arguments.firstObject];
            [requestor stub:@selector(start)];
            [requests addObject:requestor];
            return requestor;
        }];
        controller = makeController(@[@"https://startup.test"]);
    });
    afterEach(^{
        [controller cancel];
        [AMAHTTPRequestor clearStubs];
        [appState destubApplicationState];
        [AMAIdentifiersTestUtilities destubIdentifierProvider];
        [AMAMetricaConfigurationTestUtilities destubConfiguration];
        [AMAPlatformDescription clearStubs];
    });

    it(@"Should implement all migration and transition cases without changing cache freshness", ^{
        NSArray *previousValues = @[NSNull.null, @NO, @YES];
        for (id previous in previousValues) {
            for (NSNumber *current in @[@NO, @YES]) {
                configuration.persistent.lastStartupYandexAdsOnlyState = previous == NSNull.null ? nil : previous;
                isYandexAdsOnly = current.boolValue;
                BOOL required = previous == NSNull.null ? isYandexAdsOnly : [previous boolValue] != isYandexAdsOnly;
                [[theValue(controller.startupConfigurationUpToDate) should] beYes];
                [[theValue(controller.startupUpdateRequired) should] equal:theValue((BOOL)required)];
                NSUInteger count = requests.count;
                [controller update];
                [[theValue(requests.count - count) should] equal:theValue(required ? 1u : 0u)];
                [controller cancel];
            }
        }
    });

    it(@"Should send and persist zero on an ordinary cache refresh", ^{
        configuration.persistent.startupUpdatedAt = nil;
        [controller update];
        [[theValue(requests.count) should] equal:theValue(1u)];
        [[requests.lastObject.request.GETParameters[@"hoyas"] should] equal:@"0"];
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] beNil];
        succeed(requests.lastObject);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@NO];
        [[theValue(controller.startupUpdateRequired) should] beNo];
    });

    it(@"Should preserve an in-flight snapshot and send one correction through normal reporting", ^{
        isYandexAdsOnly = YES;
        [controller addAdditionalStartupParameters:@{@"module": @"value", @"hoyas": @"wrong"}];
        [controller update];
        AMAHTTPRequestor *first = requests.lastObject;
        isYandexAdsOnly = NO;
        [controller addAdditionalStartupParameters:@{@"module": @"updated", @"hoyas": @"0"}];
        [controller update];
        [[theValue(requests.count) should] equal:theValue(1u)];
        [[first.request.GETParameters[@"hoyas"] should] equal:@"1"];
        succeed(first);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@YES];
        [[theValue(controller.startupConfigurationUpToDate) should] beYes];
        [[theValue(controller.startupUpdateRequired) should] beYes];

        AMADefaultReportExecutionConditionChecker *checker = [[AMADefaultReportExecutionConditionChecker alloc] init];
        [[theValue([checker canBeExecuted:controller]) should] beNo];
        [[theValue(requests.count) should] equal:theValue(2u)];
        [[requests.lastObject.request.GETParameters[@"hoyas"] should] equal:@"0"];
        [[requests.lastObject.request.GETParameters[@"module"] should] equal:@"updated"];
        succeed(requests.lastObject);
        for (NSUInteger index = 0; index < 10; ++index) {
            [[theValue([checker canBeExecuted:controller]) should] beYes];
        }
        [[theValue(requests.count) should] equal:theValue(2u)];
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@NO];
    });

    it(@"Should retry a failed correction and ignore cancelled request callbacks", ^{
        configuration.persistent.lastStartupYandexAdsOnlyState = @YES;
        [controller update];
        AMAHTTPRequestor *first = requests.lastObject;
        failRequest(first);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@YES];
        [controller update];
        AMAHTTPRequestor *second = requests.lastObject;
        succeed(first);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@YES];
        [[theValue(requests.count) should] equal:theValue(2u)];
        succeed(second);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@NO];
        [controller update];
        [[theValue(requests.count) should] equal:theValue(2u)];
    });

    it(@"Should keep the snapshot while falling back to another host", ^{
        controller = makeController(@[@"https://first.test", @"https://second.test"]);
        isYandexAdsOnly = YES;
        [controller update];
        isYandexAdsOnly = NO;
        [controller addAdditionalStartupParameters:@{@"module": @"updated", @"hoyas": @"0"}];
        AMAHTTPRequestor *first = requests.lastObject;
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
        [first.delegate httpRequestor:first didFinishWithError:error response:nil];
        [[theValue(requests.count) should] equal:theValue(2u)];
        [[requests.lastObject.request.GETParameters[@"hoyas"] should] equal:@"1"];
        [[requests.lastObject.request.GETParameters[@"module"] should] equal:@"updated"];
        succeed(requests.lastObject);
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:@YES];
        [[theValue(controller.startupUpdateRequired) should] beYes];
    });

    it(@"Should not acknowledge an unparseable successful HTTP response", ^{
        isYandexAdsOnly = YES;
        [controller update];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc]
            initWithURL:[NSURL URLWithString:@"https://startup.test"] statusCode:200
            HTTPVersion:@"HTTP/1.1" headerFields:nil];
        AMAHTTPRequestor *requestor = requests.lastObject;
        [requestor.delegate httpRequestor:requestor didFinishWithData:[NSData data] response:response];
        [[configuration.persistent.lastStartupYandexAdsOnlyState should] beNil];
        [controller update];
        [[theValue(requests.count) should] equal:theValue(2u)];
    });

    it(@"Should coalesce cache expiration and state changes and stop after each successful snapshot", ^{
        for (NSNumber *state in @[@YES, @NO, @YES, @NO]) {
            isYandexAdsOnly = state.boolValue;
            configuration.persistent.startupUpdatedAt = nil;
            NSUInteger count = requests.count;
            [controller update];
            [controller update];
            [[theValue(requests.count - count) should] equal:theValue(1u)];
            succeed(requests.lastObject);
            [[configuration.persistent.lastStartupYandexAdsOnlyState should] equal:state];
            [controller update];
            [[theValue(requests.count - count) should] equal:theValue(1u)];
        }
        controller = makeController(@[@"https://startup.test"]);
        [controller update];
        [[theValue(requests.count) should] equal:theValue(4u)];
    });
});

SPEC_END
