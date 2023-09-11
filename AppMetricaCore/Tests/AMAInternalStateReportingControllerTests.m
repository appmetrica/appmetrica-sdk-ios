
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAInternalStateReportingController.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAReporter.h"
#import "AMAReporterStateStorage.h"
#import "AMAReporterNotifications.h"

SPEC_BEGIN(AMAInternalStateReportingControllerTests)

describe(@"AMAInternalStateReportingController", ^{

    NSString *const apiKey = @"API_KEY";
    NSNumber *const interval = @23;
    NSDictionary *const expectedParameters = @{ @"stat_sending": @{ @"disabled": @YES } };

    AMACurrentQueueExecutor *__block executor = nil;
    AMADataSendingRestrictionController *__block restrictionController = nil;
    AMAStartupParametersConfiguration *__block configuration = nil;
    NSNotificationCenter *__block notificationCenter = nil;
    AMAReporterStateStorage *__block stateStorage = nil;
    AMAReporter *__block reporter = nil;

    dispatch_block_t __block callDidAddEvent = nil;

    AMAInternalStateReportingController *__block controller = nil;

    beforeEach(^{
        executor = [[AMACurrentQueueExecutor alloc] init];
        restrictionController = [AMADataSendingRestrictionController nullMock];
        [restrictionController stub:@selector(restrictionForApiKey:)
                          andReturn:theValue(AMADataSendingRestrictionForbidden)];

        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration sharedInstance];
        configuration = metricaConfiguration.startup;
        [configuration stub:@selector(statSendingDisabledReportingInterval) andReturn:interval];

        notificationCenter = [NSNotificationCenter nullMock];
        callDidAddEvent = ^{ fail(@"Did not subscribed for events"); };
        [notificationCenter stub:@selector(addObserver:selector:name:object:) withBlock:^id(NSArray *params) {
            id observer = params[0];
            SEL selector = NSSelectorFromString(params[1]);
            callDidAddEvent = ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [observer performSelector:selector
                               withObject:[NSNotification notificationWithName:@"" object:controller]];
#pragma clang diagnostic pop
            };
            return nil;
        }];
        [NSNotificationCenter stub:@selector(defaultCenter) andReturn:notificationCenter];

        reporter = [AMAReporter nullMock];
        [AMAAppMetrica stub:@selector(reporterForApiKey:) andReturn:reporter];

        stateStorage = [AMAReporterStateStorage nullMock];
        [stateStorage stub:@selector(lastStateSendDate) andReturn:[NSDate distantPast]];

        controller = [[AMAInternalStateReportingController alloc] initWithExecutor:executor
                                                             restrictionController:restrictionController];
    });

    context(@"Start", ^{
        it(@"Should register for notifications", ^{
            [[notificationCenter should] receive:@selector(addObserver:selector:name:object:)
                                   withArguments:controller, kw_any(), kAMAReporterDidAddEventNotification, nil];
            [controller start];
        });
        context(@"With registered apiKey", ^{
            beforeEach(^{
                [controller registerStorage:stateStorage forApiKey:apiKey];
            });
            it(@"Should report", ^{
                [[reporter should] receive:@selector(reportInternalState:onFailure:)
                             withArguments:expectedParameters, kw_any()];
                [controller start];
            });
        });
    });
    context(@"Shutdoen", ^{
        it(@"Should unregister for notifications", ^{
            [[notificationCenter should] receive:@selector(removeObserver:name:object:)
                                   withArguments:controller, kAMAReporterDidAddEventNotification, nil];
            [controller shutdown];
        });
    });

    context(@"After start", ^{
        beforeEach(^{
            [controller start];
        });

        context(@"Before apiKey registration", ^{
            it(@"Should not update report date", ^{
                [[stateStorage shouldNot] receive:@selector(markStateSentNow)];
                callDidAddEvent();
            });
            it(@"Should not report", ^{
                [[reporter shouldNot] receive:@selector(reportInternalState:onFailure:)];
                callDidAddEvent();
            });
        });
        context(@"After apiKey registration", ^{
            beforeEach(^{
                [controller registerStorage:stateStorage forApiKey:apiKey];
            });

            it(@"Should save report date", ^{
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:42];
                [NSDate stub:@selector(date) andReturn:date];
                [[stateStorage should] receive:@selector(markStateSentNow)];
                callDidAddEvent();
            });
            it(@"Should request reporter", ^{
                [[AMAAppMetrica should] receive:@selector(reporterForApiKey:) withArguments:apiKey];
                callDidAddEvent();
            });
            it(@"Should report", ^{
                [[reporter should] receive:@selector(reportInternalState:onFailure:)
                             withArguments:expectedParameters, kw_any()];
                callDidAddEvent();
            });

            context(@"Stat sending enabled", ^{
                beforeEach(^{
                    [restrictionController stub:@selector(restrictionForApiKey:)
                                      andReturn:theValue(AMADataSendingRestrictionAllowed)];
                });
                it(@"Should not update report date", ^{
                    [[stateStorage shouldNot] receive:@selector(markStateSentNow)];
                    callDidAddEvent();
                });
                it(@"Should not report", ^{
                    [[reporter shouldNot] receive:@selector(reportInternalState:onFailure:)];
                    callDidAddEvent();
                });
            });
        });

        context(@"Interval not passed", ^{
            beforeEach(^{
                [stateStorage stub:@selector(lastStateSendDate) andReturn:[NSDate dateWithTimeIntervalSince1970:0]];
                [controller registerStorage:stateStorage forApiKey:apiKey];
                [NSDate stub:@selector(date) andReturn:[NSDate dateWithTimeIntervalSince1970:20]];
            });
            it(@"Should not update report date", ^{
                [[stateStorage shouldNot] receive:@selector(markStateSentNow)];
                callDidAddEvent();
            });
            it(@"Should not report", ^{
                [[reporter shouldNot] receive:@selector(reportInternalState:onFailure:)];
                callDidAddEvent();
            });
        });
    });

});

SPEC_END
