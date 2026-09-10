#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAFirstActivationDetector.h"
#import "AMASavedAppMetricaConfigRepository.h"

SPEC_BEGIN(AMAConfigForAnonymousActivationProviderTests)

describe(@"AMAConfigForAnonymousActivationProvider", ^{
    
    AMAConfigForAnonymousActivationProvider *__block provider = nil;
    AMAMetricaPersistentConfiguration *__block persistentMock = nil;
    AMADefaultAnonymousConfigProvider *__block defaultProvider = nil;
    AMAFirstActivationDetector *__block firstActivationDetector = nil;
    AMASavedAppMetricaConfigRepository *__block repository = nil;

    beforeEach(^{
        persistentMock = [AMAMetricaPersistentConfiguration nullMock];
        defaultProvider = [[AMADefaultAnonymousConfigProvider alloc] init];
        firstActivationDetector = [[AMAFirstActivationDetector alloc] init];
        repository = [AMASavedAppMetricaConfigRepository nullMock];
        
        provider = [[AMAConfigForAnonymousActivationProvider alloc] initWithStorage:persistentMock
                                                                    defaultProvider:defaultProvider
                                                            firstActivationDetector:firstActivationDetector
                                                                         repository:repository];
    });
    
    context(@"With valid saved configuration", ^{
        it(@"should return the repository configuration", ^{
            AMAAppMetricaConfiguration *configurationMock = [AMAAppMetricaConfiguration nullMock];
            [repository stub:@selector(validSavedConfig) andReturn:configurationMock];
            
            [[[provider configuration] should] equal:configurationMock];
        });
    });
    
    context(@"Without valid saved configuration", ^{
        beforeEach(^{
            [repository stub:@selector(validSavedConfig) andReturn:nil];
        });

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
