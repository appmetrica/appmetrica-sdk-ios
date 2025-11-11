
#import <Foundation/Foundation.h>
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import "AMAAttributionController.h"
#import "AMAAttributionModelConfiguration.h"
#import "AMAReporter.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAMetricaConfiguration.h"

SPEC_BEGIN(AMAAttributionControllerTests)

describe(@"AMAAttributionController", ^{
    
    AMAAttributionController *__block controller;
    AMAMetricaPersistentConfiguration *__block persistentConfiguration = nil;
    
    beforeEach(^{
        persistentConfiguration = [AMAMetricaPersistentConfiguration nullMock];
        AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration nullMock];
        [metricaConfiguration stub:@selector(persistent) andReturn:persistentConfiguration];
        [AMAMetricaConfiguration stub:@selector(sharedInstance) andReturn:metricaConfiguration];
    });
    afterEach(^{
        [AMAMetricaConfiguration clearStubs];
    });
    
    context(@"Shared instance", ^{
        it(@"Should be the same", ^{
            controller = [AMAAttributionController sharedInstance];
            [[[AMAAttributionController sharedInstance] should] equal:controller];
        });
    });
    
    if (@available(iOS 14.0, *)) {
        context(@"Set main reporter", ^{
            AMAReporter *__block reporter;
            beforeEach(^{
                reporter = [AMAReporter nullMock];
            });
            it(@"Should not set up if no config and no first startup", ^{
                [persistentConfiguration stub:@selector(hadFirstStartup) andReturn:theValue(NO)];
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                [[persistentConfiguration shouldNot] receive:@selector(registerForAttributionTime)];
                [[persistentConfiguration shouldNot] receive:@selector(setCheckedInitialAttribution:)];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.mainReporter = reporter;
            });
            it(@"Should not set up if no config and had first startup", ^{
                [persistentConfiguration stub:@selector(hadFirstStartup) andReturn:theValue(YES)];
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                [[persistentConfiguration shouldNot] receive:@selector(registerForAttributionTime)];
                [[persistentConfiguration should] receive:@selector(setCheckedInitialAttribution:) withArguments:theValue(YES)];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.mainReporter = reporter;
            });
            it(@"Should not set up if timeout passed", ^{
                AMAAttributionModelConfiguration *config =
                [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                    maxSavedRevenueIDs:nil
                                                stopSendingTimeSeconds:@100
                                                            conversion:nil
                                                               revenue:nil
                                                            engagement:nil];
                controller = [[AMAAttributionController alloc] initWithConfig:config];
                NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-101) defaultInterval:0]];
                [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.mainReporter = reporter;
            });
            it(@"Should set up", ^{
                AMAAttributionModelConfiguration *config =
                [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                    maxSavedRevenueIDs:nil
                                                stopSendingTimeSeconds:@100
                                                            conversion:nil
                                                               revenue:nil
                                                            engagement:nil];
                controller = [[AMAAttributionController alloc] initWithConfig:config];
                NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-97) defaultInterval:0]];
                [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                [[reporter should] receive:@selector(setAttributionChecker:)];
                controller.mainReporter = reporter;
            });
            context(@"Already inited", ^{
                beforeEach(^{
                    AMAAttributionModelConfiguration *config =
                    [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                        maxSavedRevenueIDs:nil
                                                    stopSendingTimeSeconds:@100
                                                                conversion:nil
                                                                   revenue:nil
                                                                engagement:nil];
                    controller = [[AMAAttributionController alloc] initWithConfig:config];
                    NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-97) defaultInterval:0]];
                    [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                    [[reporter should] receive:@selector(setAttributionChecker:)];
                    controller.mainReporter = reporter;
                });
                it(@"Should not set up again", ^{
                    [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                    controller.mainReporter = reporter;
                });
            });
        });
        context(@"Set config", ^{
            AMAReporter *__block reporter;
            beforeEach(^{
                reporter = [AMAReporter nullMock];
            });
            it(@"Should not set up if no reporter", ^{
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                [[persistentConfiguration shouldNot] receive:@selector(registerForAttributionTime)];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.config =
                [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                    maxSavedRevenueIDs:nil
                                                stopSendingTimeSeconds:@100
                                                            conversion:nil
                                                               revenue:nil
                                                            engagement:nil];
            });
            it(@"Should not set up if timeout passed", ^{
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                controller.mainReporter = reporter;
                NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-101) defaultInterval:0]];
                [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                                        maxSavedRevenueIDs:nil
                                                                    stopSendingTimeSeconds:@100
                                                                                conversion:nil
                                                                                   revenue:nil
                                                                                engagement:nil];
            });
            it(@"Should set up", ^{
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                controller.mainReporter = reporter;
                NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-97) defaultInterval:0]];
                [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                [[reporter should] receive:@selector(setAttributionChecker:)];
                controller.config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                                        maxSavedRevenueIDs:nil
                                                                    stopSendingTimeSeconds:@100
                                                                                conversion:nil
                                                                                   revenue:nil
                                                                                engagement:nil];
            });
            it(@"Should not set up if config is nil and did not have first startup", ^{
                [persistentConfiguration stub:@selector(hadFirstStartup) andReturn:theValue(NO)];
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                controller.mainReporter = reporter;
                [[persistentConfiguration shouldNot] receive:@selector(registerForAttributionTime)];
                [[persistentConfiguration shouldNot] receive:@selector(setCheckedInitialAttribution:)];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.config = nil;
            });
            it(@"Should not set up if config is nil and had first startup", ^{
                [persistentConfiguration stub:@selector(hadFirstStartup) andReturn:theValue(YES)];
                controller = [[AMAAttributionController alloc] initWithConfig:nil];
                controller.mainReporter = reporter;
                [[persistentConfiguration shouldNot] receive:@selector(registerForAttributionTime)];
                [[persistentConfiguration should] receive:@selector(setCheckedInitialAttribution:) withArguments:theValue(YES)];
                [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                controller.config = nil;
            });
            context(@"Already inited", ^{
                beforeEach(^{
                    AMAAttributionModelConfiguration *config =
                    [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                        maxSavedRevenueIDs:nil
                                                    stopSendingTimeSeconds:@100
                                                                conversion:nil
                                                                   revenue:nil
                                                                engagement:nil];
                    controller = [[AMAAttributionController alloc] initWithConfig:config];
                    NSDate *registerTime = [[NSDate date] dateByAddingTimeInterval:[AMATimeUtilities intervalWithNumber:@(-97) defaultInterval:0]];
                    [persistentConfiguration stub:@selector(registerForAttributionTime) andReturn:registerTime];
                    [[reporter should] receive:@selector(setAttributionChecker:)];
                    controller.mainReporter = reporter;
                });
                it(@"Should not set up again", ^{
                    [[reporter shouldNot] receive:@selector(setAttributionChecker:)];
                    controller.config = [[AMAAttributionModelConfiguration alloc] initWithType:AMAAttributionModelTypeConversion
                                                                            maxSavedRevenueIDs:nil
                                                                        stopSendingTimeSeconds:@100
                                                                                    conversion:nil
                                                                                       revenue:nil
                                                                                    engagement:nil];
                });
            });
        });
    };
});

SPEC_END
