
#import <Kiwi/Kiwi.h>
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAFirstActivationDetector.h"

SPEC_BEGIN(AMAConfigForAnonymousActivationProviderTests)

describe(@"AMAConfigForAnonymousActivationProvider", ^{
    
    AMAConfigForAnonymousActivationProvider *__block provider = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;
    AMADefaultAnonymousConfigProvider *__block defaultProvider = nil;
    AMAFirstActivationDetector *__block firstActivationDetector = nil;

    beforeEach(^{
        persistentMock = [AMAMetricaPersistentConfiguration nullMock];
        defaultProvider = [[AMADefaultAnonymousConfigProvider alloc] init];
        firstActivationDetector = [[AMAFirstActivationDetector alloc] init];
        
        provider = [[AMAConfigForAnonymousActivationProvider alloc] initWithStorage:persistentMock
                                                                    defaultProvider:defaultProvider
                                                            firstActivationDetector:firstActivationDetector];
    });
    
    context(@"With stored configuration", ^{
        it(@"should return the persistent configuration", ^{
            AMAAppMetricaConfiguration *configurationMock = [AMAAppMetricaConfiguration nullMock];
            [persistentMock stub:@selector(appMetricaClientConfiguration) andReturn:configurationMock];
            
            [[[provider configuration] should] equal:configurationMock];
        });
    });
    
    context(@"Without stored configuration", ^{
        it(@"should return the default provider configuration", ^{
            [[[provider configuration].APIKey should] equal:[defaultProvider configuration].APIKey];
        });
        
        context(@"with first activation", ^{
            it(@"should set handleFirstActivationAsUpdate to YES", ^{
                [firstActivationDetector stub:@selector(isFirstLibraryReporterActivation) andReturn:theValue(NO)];
                
                [[theValue([provider configuration].handleFirstActivationAsUpdate) should] beYes];
            });
        });
        
        context(@"with next activation", ^{
            it(@"should not change handleFirstActivationAsUpdate", ^{
                [firstActivationDetector stub:@selector(isFirstLibraryReporterActivation) andReturn:theValue(YES)];
                
                [[theValue([provider configuration].handleFirstActivationAsUpdate) should] beNo];
            });
        });
    });
    
});

SPEC_END
