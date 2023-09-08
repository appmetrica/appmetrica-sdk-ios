
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
    
    context(@"BOOL values", ^{
        NSNumber *const value = @YES;
        beforeEach(^{
            [dataProviderMock stub:@selector(objectForKey:error:) andReturn:value];
        });
        context(@"dynamicLibraryCrashHookEnabled", ^{
            NSString *const key = @"libs.dynamic.hook.enabled";
            it(@"Should use valid key", ^{
                [[dataProviderMock should] receive:@selector(objectForKey:error:) withArguments:key, kw_any()];
                [configuration dynamicLibraryCrashHookEnabled];
            });
            it(@"Should return valid value", ^{
                [[theValue(configuration.dynamicLibraryCrashHookEnabled) should] beYes];
            });
            it(@"Should return NO by default", ^{
                [dataProviderMock stub:@selector(objectForKey:error:) andReturn:nil];
                [[theValue(configuration.dynamicLibraryCrashHookEnabled) should] beNo];
            });
            it(@"Should not save if value does not differ", ^{
                [[dataProviderMock shouldNot] receive:@selector(saveObject:forKey:error:)];
                configuration.dynamicLibraryCrashHookEnabled = value.boolValue;
            });
            it(@"Should save valid value", ^{
                [[dataProviderMock should] receive:@selector(saveObject:forKey:error:) withArguments:@NO, key, kw_any()];
                configuration.dynamicLibraryCrashHookEnabled = NO;
            });
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
            it(@"Should not save new value", ^{
                [[dataProviderMock shouldNot] receive:@selector(saveObject:forKey:error:)];
                configuration.UUID = value;
            });
            it(@"Should save intial value", ^{
                [dataProviderMock stub:@selector(objectForKey:error:) andReturn:nil];
                [[dataProviderMock should] receive:@selector(saveObject:forKey:error:) withArguments:value, key, kw_any()];
                configuration.UUID = value;
            });
        });
    });
    context(@"Observing", ^{

        id<AMAInstantFeaturesObserver> __block observer = nil;

        beforeEach(^{
            observer = [KWMock mockForProtocol:@protocol(AMAInstantFeaturesObserver)];
            [configuration addAMAObserver:observer];
        });

        it(@"Should add observer", ^{
            [[configuration.observers should] contain:observer];
        });

        it(@"Should remove observer", ^{
            [configuration removeAMAObserver:observer];
            [[configuration.observers shouldNot] contain:observer];
        });

        it(@"Should notify of the changes", ^{
            [[(KWMock *)observer should] receive:@selector(instantFeaturesConfigurationDidUpdate:)];
            [dataProviderMock stub:@selector(objectForKey:error:) andReturn:@YES];
            configuration.dynamicLibraryCrashHookEnabled = NO;
        });

        it(@"Should not notify if nothing changed", ^{
            [[(KWMock *)observer shouldNot] receive:@selector(instantFeaturesConfigurationDidUpdate:)];
            [dataProviderMock stub:@selector(objectForKey:error:) andReturn:@YES];
            configuration.dynamicLibraryCrashHookEnabled = YES;
        });

        it(@"Should notify if startup changed", ^{
            [[(KWMock *)observer should] receive:@selector(instantFeaturesConfigurationDidUpdate:)];
            [configuration startupUpdateCompletedWithConfiguration:[KWMock nullMock]];
        });
    });
});

SPEC_END
