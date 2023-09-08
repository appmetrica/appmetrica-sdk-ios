
#import <Kiwi/Kiwi.h>
#import "AMAExtensionsReportExecutionConditionProvider.h"
#import "AMAMetricaConfigurationTestUtilities.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>

SPEC_BEGIN(AMAExtensionsReportExecutionContidionProviderTests)

describe(@"AMAExtensionsReportExecutionConditionProvider", ^{

    AMAMetricaConfiguration *__block configuration = nil;
    AMAExtensionsReportExecutionConditionProvider *__block provider = nil;

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configuration = [AMAMetricaConfiguration sharedInstance];
        provider = [[AMAExtensionsReportExecutionConditionProvider alloc] initWithConfiguration:configuration];
    });

    context(@"Launch Delay", ^{
        it(@"Should return valid launch delay", ^{
            NSTimeInterval const launchDelay = 15.16;
            [configuration.startup stub:@selector(extensionsCollectingLaunchDelay) andReturn:@(launchDelay)];
            [[theValue(provider.launchDelay) should] equal:launchDelay withDelta:0.001];
        });
        it(@"Should return predefined value if not available", ^{
            [[theValue(provider.launchDelay) should] equal:3.0 withDelta:0.001];
        });
    });
    context(@"Enabled", ^{
        it(@"Should return YES", ^{
            [configuration.startup stub:@selector(extensionsCollectingEnabled) andReturn:theValue(YES)];
            [[theValue(provider.enabled) should] beYes];
        });
        it(@"Should return NO", ^{
            [configuration.startup stub:@selector(extensionsCollectingEnabled) andReturn:theValue(NO)];
            [[theValue(provider.enabled) should] beNo];
        });
    });
    context(@"Execution Condition", ^{
        AMAIntervalExecutionCondition *__block executionCondition = nil;
        beforeEach(^{
            SEL selector = @selector(initWithLastExecuted:interval:underlyingCondition:);
            executionCondition = [AMAIntervalExecutionCondition stubbedNullMockForInit:selector];
        });
        it(@"Should create condition with valid default parameters", ^{
            [[executionCondition should] receive:@selector(initWithLastExecuted:interval:underlyingCondition:)
                                   withArguments:nil, theValue(24.0 * 3600.0), nil];
            [provider executionCondition];
        });
        it(@"Should create condition with valid defined parameters", ^{
            NSTimeInterval interval = 2.0;
            NSDate *lastDate = [NSDate date];
            [configuration.startup stub:@selector(extensionsCollectingInterval) andReturn:@(interval)];
            [configuration.persistent stub:@selector(extensionsLastReportDate) andReturn:lastDate];
            [[executionCondition should] receive:@selector(initWithLastExecuted:interval:underlyingCondition:)
                                   withArguments:lastDate, theValue(interval), nil];
            [provider executionCondition];
        });
        it(@"Should return valid condition", ^{
            [[(NSObject *)provider.executionCondition should] equal:executionCondition];
        });
    });
    context(@"Executoed", ^{
        it(@"Should save current date", ^{
            NSDate *now = [NSDate date];
            [NSDate stub:@selector(date) andReturn:now];
            [[configuration.persistent should] receive:@selector(setExtensionsLastReportDate:) withArguments:now];
            [provider executed];
        });
    });

});

SPEC_END
