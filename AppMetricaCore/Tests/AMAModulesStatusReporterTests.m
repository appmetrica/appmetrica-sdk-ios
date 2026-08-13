
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAInternalEventsReporter.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaPersistentConfigurationMock.h"
#import "AMAModulesStatusReporter.h"
#import "AMAModulesController.h"
#import "AMAModulesStatusReportState.h"

SPEC_BEGIN(AMAModulesStatusReporterTests)

describe(@"AMAModulesStatusReporter", ^{

    AMAInternalEventsReporter *__block internalReporter = nil;
    AMAModulesController *__block modulesController = nil;
    AMAMetricaPersistentConfigurationMock *__block persistentConfiguration = nil;
    AMADateProviderMock *__block dateProvider = nil;
    AMAModulesStatusReporter *__block reporter = nil;

    NSDictionary *(^expectedPayloadForStatuses)(NSDictionary *, NSDate *) = ^(NSDictionary *statuses, NSDate *date) {
        NSArray *sortedKeys = [statuses.allKeys sortedArrayUsingSelector:@selector(compare:)];
        NSMutableArray *items = [NSMutableArray array];
        for (NSString *name in sortedKeys) {
            [items addObject:@{ @"moduleName": name, @"loaded": @([statuses[name] boolValue]) }];
        }
        int64_t lastSendTime = (int64_t)(date.timeIntervalSince1970 * 1000.0);
        return @{
            @"modulesStatus": [items copy],
            @"lastSendTime": @(lastSendTime),
        };
    };

    beforeEach(^{
        internalReporter = [AMAInternalEventsReporter nullMock];
        modulesController = [AMAModulesController nullMock];
        persistentConfiguration = [[AMAMetricaPersistentConfigurationMock alloc] init];
        dateProvider = [[AMADateProviderMock alloc] init];
        reporter = [[AMAModulesStatusReporter alloc] initWithReporter:internalReporter
                                                     modulesController:modulesController
                                               persistentConfiguration:persistentConfiguration
                                                          dateProvider:dateProvider];
    });

    context(@"No discovered modules", ^{
        beforeEach(^{
            [modulesController stub:@selector(moduleStatuses) andReturn:@{}];
        });

        it(@"Should not report any event", ^{
            [[internalReporter shouldNot] receive:@selector(reportModulesStatusWithParameters:)];
            [reporter report];
        });

        it(@"Should not touch persistent configuration", ^{
            [reporter report];
            [[persistentConfiguration.modulesStatusReportState should] beNil];
        });
    });

    context(@"Has modules", ^{
        NSDictionary *const statuses = @{
            @"AppMetricaYandexCore": @YES,
            @"AppMetricaCrashes": @YES,
            @"AppMetricaAdSupport": @YES,
            @"AppMetricaScreenshot": @YES,
        };
        NSDate *__block now = nil;

        beforeEach(^{
            [modulesController stub:@selector(moduleStatuses) andReturn:statuses];
            now = [NSDate dateWithTimeIntervalSince1970:1700000000];
            [dateProvider freezeWithDate:now];
        });

        context(@"No previous state", ^{
            it(@"Should report event with sorted modules array", ^{
                [[internalReporter should] receive:@selector(reportModulesStatusWithParameters:)
                                     withArguments:expectedPayloadForStatuses(statuses, now)];
                [reporter report];
            });

            it(@"Should save report state with current date and statuses", ^{
                [reporter report];
                AMAModulesStatusReportState *saved = persistentConfiguration.modulesStatusReportState;
                [[saved shouldNot] beNil];
                [[saved.lastSentDate should] equal:now];
                [[saved.moduleStatuses should] equal:statuses];
            });
        });

        context(@"Has previous state", ^{
            it(@"Should not report when statuses are equal and interval has not passed", ^{
                NSDate *recent = [now dateByAddingTimeInterval:-3600];
                persistentConfiguration.modulesStatusReportState = [[AMAModulesStatusReportState alloc]
                    initWithLastSentDate:recent
                    moduleStatuses:statuses];

                [[internalReporter shouldNot] receive:@selector(reportModulesStatusWithParameters:)];
                [reporter report];

                [[persistentConfiguration.modulesStatusReportState.lastSentDate should] equal:recent];
            });

            it(@"Should report when interval has passed even if statuses are equal", ^{
                NSDate *old = [now dateByAddingTimeInterval:-(24 * 60 * 60 + 1)];
                persistentConfiguration.modulesStatusReportState = [[AMAModulesStatusReportState alloc]
                    initWithLastSentDate:old
                    moduleStatuses:statuses];

                [[internalReporter should] receive:@selector(reportModulesStatusWithParameters:)
                                     withArguments:expectedPayloadForStatuses(statuses, now)];
                [reporter report];

                [[persistentConfiguration.modulesStatusReportState.lastSentDate should] equal:now];
                [[persistentConfiguration.modulesStatusReportState.moduleStatuses should] equal:statuses];
            });

            it(@"Should report when statuses changed even within interval", ^{
                NSDate *recent = [now dateByAddingTimeInterval:-3600];
                NSDictionary *oldStatuses = @{ @"AppMetricaYandexCore": @YES };
                persistentConfiguration.modulesStatusReportState = [[AMAModulesStatusReportState alloc]
                    initWithLastSentDate:recent
                    moduleStatuses:oldStatuses];

                [[internalReporter should] receive:@selector(reportModulesStatusWithParameters:)
                                     withArguments:expectedPayloadForStatuses(statuses, now)];
                [reporter report];

                [[persistentConfiguration.modulesStatusReportState.lastSentDate should] equal:now];
                [[persistentConfiguration.modulesStatusReportState.moduleStatuses should] equal:statuses];
            });

            it(@"Should report when previous lastSentDate is nil", ^{
                persistentConfiguration.modulesStatusReportState = [[AMAModulesStatusReportState alloc]
                    initWithLastSentDate:nil
                    moduleStatuses:statuses];

                [[internalReporter should] receive:@selector(reportModulesStatusWithParameters:)
                                     withArguments:expectedPayloadForStatuses(statuses, now)];
                [reporter report];
            });
        });
    });
});

SPEC_END
