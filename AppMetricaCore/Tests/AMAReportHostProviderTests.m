
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAReportHostProvider.h"
#import "AMAMetricaConfigurationTestUtilities.h"

SPEC_BEGIN(AMAReportHostProviderTests)

describe(@"AMAReportHostProvider", ^{
    
    AMAMetricaConfiguration *__block configuration = nil;
    AMAReportHostProvider *__block provider = nil;
    NSString *apiKey = @"aaa-bbb-ccc";

    beforeEach(^{
        [AMAMetricaConfigurationTestUtilities stubConfigurationWithNullMock];
        configuration = [AMAMetricaConfiguration sharedInstance];
    });
    
    context(@"No hosts", ^{

        it(@"Should return nil for current", ^{
            [[provider.current should] beNil];
        });
        
        it(@"Should return nil for next", ^{
            [[[provider next] should] beNil];
        });
        
        it(@"Should return nil for current after reset", ^{
            [provider reset];
            [[provider.current should] beNil];
        });
        
        context(@"After hosts update", ^{
            
            NSArray *const hosts = @[ @"first", @"second" ];

            beforeEach(^{
                [configuration.startup stub:@selector(reportHosts) andReturn:hosts];
                provider = [[AMAReportHostProvider alloc] init];
            });
            
            it(@"Should return nil for current", ^{
                [[provider.current should] beNil];
            });
            
            it(@"Should return first host for current after reset", ^{
                [provider reset];
                [[provider.current should] equal:hosts.firstObject];
            });
            
        });
        
    });

    context(@"Has hosts for different api key", ^{

        beforeEach(^{
            NSString *anotherApiKey = @"bbb-ccc-ddd";
        });

        it(@"Should return nil for current after reset", ^{
            [provider reset];
            [[provider.current should] beNil];
        });
    });

    context(@"Multiple", ^{
        
        NSArray *const hosts = @[ @"first", @"second", @"third" ];

        beforeEach(^{
            [configuration.startup stub:@selector(reportHosts) andReturn:hosts];
            provider = [[AMAReportHostProvider alloc] init];
            [provider reset];
        });
        
        it(@"Should return first host for current", ^{
            [[provider.current should] equal:hosts.firstObject];
        });
        
        it(@"Should return second host for next", ^{
            [[[provider next] should] equal:hosts[1]];
        });
        
        it(@"Should return last host for current after 2 steps", ^{
            [provider next];
            [provider next];
            [[provider.current should] equal:hosts.lastObject];
        });
        
        it(@"Should return nil for next after 2 steps", ^{
            [provider next];
            [provider next];
            [[[provider next] should] beNil];
        });
        
        it(@"Should return nil for current after 3 steps", ^{
            [provider next];
            [provider next];
            [provider next];
            [[provider.current should] beNil];
        });
        
        it(@"Should return first host for current after 1 step and reset", ^{
            [provider next];
            [provider reset];
            [[provider.current should] equal:hosts.firstObject];
        });
        
        it(@"Should return first host for current after 3 steps and reset", ^{
            [provider next];
            [provider next];
            [provider next];
            [provider reset];
            [[provider.current should] equal:hosts.firstObject];
        });
        
    });
    
    it(@"Should conform to AMAResettableIterable", ^{
        [[provider should] conformToProtocol:@protocol(AMAResettableIterable)];
    });
});

SPEC_END
