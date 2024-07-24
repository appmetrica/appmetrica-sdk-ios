
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAUrgentEventCountDispatchStrategy.h"
#import "AMAEventCountDispatchStrategy+Private.h"
#import "AMAEvent.h"
#import "AMADispatchStrategy+Private.h"
#import "AMADispatchStrategyDelegate.h"
#import "AMAReporterNotifications.h"
#import "AMAReporter.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporterStorage.h"
#import "AMAEventStorage.h"
#import "AMAReportExecutionConditionChecker.h"
#import "AMAStartupController.h"

SPEC_BEGIN(AMAUrgentEventCountDispatchStrategyTests)

describe(@"AMAUrgentEventCountDispatchStrategy", ^{
    id<AMADispatchStrategyDelegate> __block delegateMock = nil;
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAReporterStorage *__block reporterStorage = nil;
    id __block conditionChecker = nil;

    beforeEach(^{
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        reporterStorage = reporterTestHelper.appReporter.reporterStorage;
    });


    AMAUrgentEventCountDispatchStrategy * (^mockEnv)(unsigned int) = ^ AMAUrgentEventCountDispatchStrategy *(unsigned int eventCount) {
        delegateMock = [KWMock mockForProtocol:@protocol(AMADispatchStrategyDelegate)];
        AMATestDelayedManualExecutor *manualExecutor = [AMATestDelayedManualExecutor new];
        conditionChecker = [KWMock nullMockForProtocol:@protocol(AMAReportExecutionConditionChecker)];
        [reporterStorage.eventStorage stub:@selector(totalCountOfEventsWithTypes:excludingTypes:) andReturn:theValue(eventCount)];
        AMAUrgentEventCountDispatchStrategy *strategy = [[AMAUrgentEventCountDispatchStrategy alloc] initWithDelegate:delegateMock
                                                                                                              storage:reporterStorage
                                                                                                             executor:manualExecutor
                                                                                            executionConditionChecker:conditionChecker];
        return strategy;
    };

    void (^postNotificationWithEventType)(AMAEventType, AMAEventCountDispatchStrategy *) = ^(AMAEventType type, AMAEventCountDispatchStrategy *strategy) {
        NSDictionary *userInfo = @{
            kAMAReporterDidAddEventNotificationUserInfoKeyApiKey : reporterStorage.apiKey,
            kAMAReporterDidAddEventNotificationUserInfoKeyEventType : @(type)
        };
        NSNotification *notif = [NSNotification notificationWithName:kAMAReporterDidAddEventNotification
                                                              object:nil
                                                            userInfo:userInfo];
        [strategy handleSessionDidAddEventNotification:notif];
    };

    it(@"Should return valid event types", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
        [[[strategy includedEventTypes] should] containObjectsInArray:@[
            @(AMAEventTypeInit),
            @(AMAEventTypeUpdate),
            @(AMAEventTypeFirst),
            @(AMAEventTypeStart),
        ]];
    });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    it(@"Should trigger dispatch if there is any event with specified type", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(2);
        [[(id)strategy.delegate should] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
        [strategy start];
        [strategy.executor execute:^{}];
    });

    it(@"Should not trigger dispatch if there is no important events", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
        [[(id)strategy.delegate shouldNot] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
        [strategy start];
        [strategy.executor execute:^{}];
    });

    it(@"Should not react on notification if event type is not in list", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
        [[strategy shouldNot] receive:@selector(updateEventsCount)];
        [strategy start];
        postNotificationWithEventType(AMAEventTypeClient, strategy);
        [strategy.executor execute:^{}];
    });

    it(@"Should react on notification for EVENT_INIT", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
        [[strategy should] receive:@selector(updateEventsCount)];
        [strategy start];
        postNotificationWithEventType(AMAEventTypeInit, strategy);
        [strategy.executor execute:^{}];
    });

    it(@"Should react on notification for EVENT_START", ^{
        AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
        [[strategy should] receive:@selector(updateEventsCount)];
        [strategy start];
        postNotificationWithEventType(AMAEventTypeStart, strategy);
        [strategy.executor execute:^{}];
    });
#pragma clang diagnostic pop
    context(@"Can be executed", ^{
        AMAStartupController *__block controller = nil;
        beforeEach(^{
            controller = [AMAStartupController nullMock];
        });
        it(@"Should return YES", ^{
            AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
            [conditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(YES) withArguments:controller];
            [[theValue([strategy canBeExecuted:controller]) should] beYes];
        });
        it(@"Should return NO", ^{
            AMAUrgentEventCountDispatchStrategy *strategy = mockEnv(0);
            [conditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(NO) withArguments:controller];
            [[theValue([strategy canBeExecuted:controller]) should] beNo];
        });
    });
    
    it(@"Should be subclass of DispatchStrategy", ^{
        [[mockEnv(0) should] beKindOfClass:AMAEventCountDispatchStrategy.class];
    });
});

SPEC_END
