
#import <Kiwi/Kiwi.h>

#import "AMAInstantFeaturesConfiguration.h"
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import "AMAJSONFileKVSDataProvider.h"

SPEC_BEGIN(AMAInstantFeaturesConfigurationTests)

describe(@"AMAInstantFeaturesConfiguration", ^{
    
    AMAInstantFeaturesConfiguration *__block configuration = nil;
    AMAJSONFileKVSDataProvider *__block dataProviderMock = nil;
    
    beforeEach(^{
        dataProviderMock = [AMAJSONFileKVSDataProvider nullMock];
        configuration = [[AMAInstantFeaturesConfiguration alloc] initWithJSONDataProvider:dataProviderMock];
    });

    context(@"Shared instance", ^{
        beforeEach(^{
            configuration = [AMAInstantFeaturesConfiguration sharedInstance];
        });
        it(@"Should not be nil", ^{
            [[configuration shouldNot] beNil];
        });
        it (@"should return the same instance second time", ^{
            [[[AMAInstantFeaturesConfiguration sharedInstance] should] equal:configuration];
        });
    });
    
    context(@"NSString values", ^{
        NSString *const value = @"VALUE";
        beforeEach(^{
            [dataProviderMock stub:@selector(objectForKey:error:) andReturn:value];
        });
        context(@"UUID", ^{
            NSString *const key = @"uuid";
            it(@"Should use valid key", ^{
                [[dataProviderMock should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [configuration UUID];
            });
            it(@"Should return valid value", ^{
                [[configuration.UUID should] equal:value];
            });
        });
    });
});

SPEC_END
