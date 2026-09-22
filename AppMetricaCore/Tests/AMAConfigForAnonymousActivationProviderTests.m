#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
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
        it(@"should return the repository configuration and allow persist", ^{
            AMAAppMetricaConfiguration *configurationMock = [AMAAppMetricaConfiguration nullMock];
            [repository stub:@selector(validSavedConfigDidUpdate:) withBlock:^id(NSArray *params) {
                BOOL *didUpdatePtr = [params[0] pointerValue];
                if (didUpdatePtr != NULL) {
                    *didUpdatePtr = YES;
                }
                return configurationMock;
            }];

            BOOL canPersist = NO;
            [[[provider configurationCanPersist:&canPersist] should] equal:configurationMock];
            [[theValue(canPersist) should] beYes];
        });
    });
    
    context(@"Without valid saved configuration", ^{
        beforeEach(^{
            [repository stub:@selector(validSavedConfigDidUpdate:) withBlock:^id(NSArray *params) {
                BOOL *didUpdatePtr = [params[0] pointerValue];
                if (didUpdatePtr != NULL) {
                    *didUpdatePtr = YES;
                }
                return nil;
            }];
        });

        it(@"should return the default provider configuration and allow persist", ^{
            BOOL canPersist = NO;
            [[[provider configurationCanPersist:&canPersist].APIKey should] equal:[defaultProvider configuration].APIKey];
            [[theValue(canPersist) should] beYes];
        });
        
        context(@"with first activation", ^{
            it(@"should set handleFirstActivationAsUpdate to YES", ^{
                [firstActivationDetector stub:@selector(isFirstLibraryReporterActivation) andReturn:theValue(NO)];
                
                [[theValue([provider configurationCanPersist:NULL].handleFirstActivationAsUpdate) should] beYes];
            });
        });
        
        context(@"with next activation", ^{
            it(@"should not change handleFirstActivationAsUpdate", ^{
                [firstActivationDetector stub:@selector(isFirstLibraryReporterActivation) andReturn:theValue(YES)];
                
                [[theValue([provider configurationCanPersist:NULL].handleFirstActivationAsUpdate) should] beNo];
            });
        });
    });

    context(@"When lock update fails", ^{
        it(@"should return default configuration and disallow persist", ^{
            [repository stub:@selector(validSavedConfigDidUpdate:) withBlock:^id(NSArray *params) {
                BOOL *didUpdatePtr = [params[0] pointerValue];
                if (didUpdatePtr != NULL) {
                    *didUpdatePtr = NO;
                }
                return nil;
            }];

            BOOL canPersist = YES;
            [[[provider configurationCanPersist:&canPersist].APIKey should] equal:[defaultProvider configuration].APIKey];
            [[theValue(canPersist) should] beNo];
        });
    });
    
});

SPEC_END
