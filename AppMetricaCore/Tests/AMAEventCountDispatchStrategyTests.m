
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAEventCountDispatchStrategy+Private.h"
#import "AMAReporter.h"
#import "AMAReporterTestHelper.h"
#import "AMAReporterStorage.h"
#import "AMAReporterNotifications.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMADefaultReportExecutionConditionChecker.h"
#import "AMAStartupController.h"

#define shouldNotEventuallyDefault shouldNotEventuallyBeforeTimingOutAfter(0.2)

SPEC_BEGIN(AMAEventCountDispatchStrategyTests)

describe(@"AMAEventCountDispatchStrategy", ^{
    AMAReporterTestHelper *__block reporterTestHelper = nil;
    AMAReporterStorage *__block reporterStorage = nil;
    AMAEventCountDispatchStrategy * __block strategy = nil;
    id __block executionConditionChecker = nil;
    id __block delegate = nil;

    beforeEach(^{
        reporterTestHelper = [[AMAReporterTestHelper alloc] init];
        reporterStorage = reporterTestHelper.appReporter.reporterStorage;
        executionConditionChecker = [KWMock nullMockForProtocol:@protocol(AMAReportExecutionConditionChecker)];
    });

	context(@"Handles configuration update", ^{
        void (^setup)(void) = ^{
            delegate = [KWMock nullMockForProtocol:@protocol(AMADispatchStrategyDelegate)];
            AMATestDelayedManualExecutor *manualExecutor = [AMATestDelayedManualExecutor new];
            strategy = [[AMAEventCountDispatchStrategy alloc] initWithDelegate:delegate
                                                                       storage:reporterStorage
                                                                      executor:manualExecutor
                                                     executionConditionChecker:executionConditionChecker];
        };
        void (^postNotifications)(AMAEventCountDispatchStrategy *, NSUInteger) =
            ^(AMAEventCountDispatchStrategy *strategy, NSUInteger notificationsNumber) {
            AMAReporter *reporter = [reporterTestHelper appReporter];
            for (NSUInteger i = 0; i < notificationsNumber; ++i) {
                [reporter reportEvent:@"Test" onFailure:nil];
            }
            [strategy.executor execute:nil];
        };
        __auto_type reportCleanupEvent = ^{
            [[reporterTestHelper appReporter] reportCleanupEvent:@{} onFailure:NULL];
            [strategy.executor execute:nil];
        };
        void (^stubConfigurationWithMaxReportsCount)(NSUInteger) = ^(NSUInteger count) {
            [AMAMetricaConfigurationTestUtilities stubConfiguration];
            AMAMetricaConfiguration *config = [AMAMetricaConfiguration sharedInstance];
            AMAMutableReporterConfiguration *mutableConfig = [config.appConfiguration mutableCopy];
            [mutableConfig setMaxReportsCount:count];
            [config stub:@selector(configurationForApiKey:) andReturn:mutableConfig];
        };
        it(@"Should call delegate when event count reaches the count set in configuration", ^{
            setup();
            stubConfigurationWithMaxReportsCount(4);
            [[delegate shouldEventually] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
            [strategy start];
            postNotifications(strategy, 3);
        });
        it(@"Should not call delegate if max reports count is 6", ^{
            setup();
            stubConfigurationWithMaxReportsCount(4);
            [[delegate shouldNotEventuallyDefault] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
            [strategy start];
            postNotifications(strategy, 2);
        });
        it(@"Should not call delegate when cleanup event reported", ^{
            setup();
            stubConfigurationWithMaxReportsCount(4);
            [[delegate shouldNotEventuallyDefault] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
            [strategy start];
            postNotifications(strategy, 2);
            reportCleanupEvent();
        });
        it(@"Should call delegate 2 times for two batches when max reports count changes from 0 to 3 and 7 events reported", ^{
            setup();
            stubConfigurationWithMaxReportsCount(0);
            [strategy start];
            postNotifications(strategy, 3);
            [NSThread sleepForTimeInterval:1];
            stubConfigurationWithMaxReportsCount(3);
            [strategy restart];
            postNotifications(strategy, 3);
        });
        it(@"Should call delegate once when max reports count is initially 2 for three events", ^{
            setup();
            [[delegate shouldEventually] receive:@selector(dispatchStrategyWantsReportingToHappen:) withCount:1];
            stubConfigurationWithMaxReportsCount(2);
            [strategy start];
            postNotifications(strategy, 2);
        });
        it(@"Should call delegate once when max reports count changes from 4 to 2 with 3 events already reported", ^{
            setup();
            [[delegate shouldEventually] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
            stubConfigurationWithMaxReportsCount(4);

            [strategy start];
            postNotifications(strategy, 2);
            stubConfigurationWithMaxReportsCount(2);
            [strategy restart];
        });
        it(@"Should not call delegate when max reports count already reported but with EVENT_CLEANUP", ^{
            setup();
            [[delegate shouldNotEventuallyDefault] receive:@selector(dispatchStrategyWantsReportingToHappen:)];
            stubConfigurationWithMaxReportsCount(4);
            [strategy start];
            postNotifications(strategy, 2);
            reportCleanupEvent();
            [strategy restart];
        });
    });
	context(@"Can be executed", ^{
	    AMAStartupController *__block controller = nil;
	    beforeEach(^{
	        controller = [AMAStartupController nullMock];
            delegate = [KWMock nullMockForProtocol:@protocol(AMADispatchStrategyDelegate)];
            AMATestDelayedManualExecutor *manualExecutor = [AMATestDelayedManualExecutor new];
            strategy = [[AMAEventCountDispatchStrategy alloc] initWithDelegate:delegate
                                                                       storage:reporterStorage
                                                                      executor:manualExecutor
                                                     executionConditionChecker:executionConditionChecker];
        });
	    it(@"Should return YES", ^{
            [executionConditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(YES) withArguments:controller];
            [[theValue([strategy canBeExecuted:controller]) should] beYes];
	    });
        it(@"Should return NO", ^{
            [executionConditionChecker stub:@selector(canBeExecuted:) andReturn:theValue(NO) withArguments:controller];
            [[theValue([strategy canBeExecuted:controller]) should] beNo];
        });
	});
    
    it(@"Should be subclass of DispatchStrategy", ^{
        [[strategy should] beKindOfClass:AMADispatchStrategy.class];
    });
});

SPEC_END
