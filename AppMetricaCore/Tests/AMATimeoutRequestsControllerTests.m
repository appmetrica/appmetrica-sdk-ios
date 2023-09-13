
#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMATimeoutRequestsController.h"
#import "AMATimeoutConfiguration.h"
#import "AMAMetricaConfiguration.h"
#import "AMAStartupParametersConfiguration.h"

SPEC_BEGIN(AMATimeoutRequestsControllerTests)

describe(@"AMATimeoutRequestsController", ^{
    
    NSDate *const testDate = [NSDate dateWithTimeIntervalSince1970:1000];
    
    AMADateProviderMock *__block dateProviderMock = nil;
    AMAStartupParametersConfiguration *__block configurationMock = nil;
    AMAPersistentTimeoutConfiguration *__block timeoutConfigurationMock = nil;
    AMATimeoutConfiguration *__block testTimeout = nil;

    AMATimeoutRequestsController *__block testController = nil;
         
    beforeEach(^{
        dateProviderMock = [[AMADateProviderMock alloc] init];
        configurationMock = [AMAStartupParametersConfiguration nullMock];
        [[AMAMetricaConfiguration sharedInstance] stub:@selector(startup) andReturn:configurationMock];
        timeoutConfigurationMock = [AMAPersistentTimeoutConfiguration mock];
        testTimeout = [[AMATimeoutConfiguration alloc] initWithLimitDate:testDate count:0];
        [timeoutConfigurationMock stub:@selector(timeoutConfigForHostType:) andReturn:testTimeout];
        [timeoutConfigurationMock stub:@selector(saveTimeoutConfig:forHostType:)];

        testController = [[AMATimeoutRequestsController alloc]  initWithHostType:@"testHost" 
                                                                  configuration:timeoutConfigurationMock 
                                                                   dateProvider:dateProviderMock];
    });
    
    context(@"Asking of access", ^{
        
        it(@"Should allow if limit date expired", ^{
            [dateProviderMock freezeWithDate:[testDate dateByAddingTimeInterval:100]];
            [[theValue(testController.isAllowed) should] equal:theValue(YES)];
        });
        it(@"Should not allow if limit date didn't expire", ^{
            [dateProviderMock freezeWithDate:[testDate dateByAddingTimeInterval:-100]];
            [[theValue(testController.isAllowed) should] equal:theValue(NO)];
        });
    });
    
    context(@"Reporting of success", ^{
        
        it(@"Should reset counter", ^{
            [timeoutConfigurationMock stub:@selector(saveTimeoutConfig:forHostType:) withBlock:^id(NSArray *params) {
                AMATimeoutConfiguration *config = params[0];
                [[theValue(config.count) should] equal:theValue(0)];
                return nil;
            }];
            [testController reportOfSuccess];
        });
        it(@"Should reset limit date", ^{
            [timeoutConfigurationMock stub:@selector(saveTimeoutConfig:forHostType:) withBlock:^id(NSArray *params) {
                AMATimeoutConfiguration *config = params[0];
                [config.limitDate shouldBeNil];
                return nil;
            }];
            [testController reportOfSuccess];
        });
    });

    __auto_type intervalShouldEqual = ^(NSTimeInterval testInterval) {
         [timeoutConfigurationMock stub:@selector(saveTimeoutConfig:forHostType:) withBlock:^id(NSArray *params) {
             AMATimeoutConfiguration *config = params[0];
             NSTimeInterval interval = [config.limitDate timeIntervalSinceDate:testDate];
             [[theValue(interval) should] equal:theValue(testInterval)];
             return nil;
         }];
    };

    context(@"Reporting of failure", ^{

        beforeEach(^{
            [dateProviderMock freezeWithDate:testDate];
        });

        it(@"Should increase timeout by 1 second after 1 failure", ^{
            intervalShouldEqual(1);
            [testController reportOfFailure];
        });
        it(@"Should increase timeout by 3 seconds after 2 failures", ^{
            [testController reportOfFailure];
            intervalShouldEqual(3);
            [testController reportOfFailure];
        });
        it(@"Should increase timeout by 31 seconds after 5 failures", ^{
            [testController reportOfFailure];
            [testController reportOfFailure];
            [testController reportOfFailure];
            [testController reportOfFailure];
            intervalShouldEqual(31);
            [testController reportOfFailure];
        });
    });

    context(@"Custom parameters", ^{
        
        beforeEach(^{
            [dateProviderMock freezeWithDate:testDate];
        });
    
        it(@"Should increase timeout by 123 after 1 failure", ^{
            [configurationMock stub:@selector(retryPolicyExponentialMultiplier) andReturn:@(123)];
            intervalShouldEqual(123);
            [testController reportOfFailure];
        });

        it(@"Should not increase timeout more than config maximum", ^{
            [testController reportOfFailure];
            [testController reportOfFailure];
            [testController reportOfFailure];
            [testController reportOfFailure];
            [configurationMock stub:@selector(retryPolicyMaxIntervalSeconds) andReturn:@(5)];
            intervalShouldEqual(5);
            [testController reportOfFailure];
        });
    });
});

SPEC_END
