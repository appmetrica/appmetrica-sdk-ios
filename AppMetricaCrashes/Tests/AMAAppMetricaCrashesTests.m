#import <Kiwi/Kiwi.h>
#import <AppMetricaTestUtils/AppMetricaTestUtils.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import "AMAAppMetricaCrashes.h"
#import "AMAAppMetricaCrashes+Private.h"
#import "AMAANRWatchdog.h"
#import "AMACrashLoader.h"
#import "AMACrashProcessor.h"
#import "AMACrashReporter.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMAAppMetricaCrashesConfiguration.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorEnvironment.h"
#import "AMAErrorModel.h"
#import "AMAErrorModelFactory.h"
#import "AMACrashReportCrash.h"
#import "AMACrashReportError.h"
#import "AMASignal.h"

@interface AMAAppMetricaCrashes () <AMAModuleActivationDelegate>
@property (nonatomic, strong) AMAErrorEnvironment *errorEnvironment;
@property (nonatomic, strong) AMAEnvironmentContainer *appEnvironment;

- (void)handlePluginInitFinished;
@end

SPEC_BEGIN(AMAAppMetricaCrashesTests)

describe(@"AMAAppMetricaCrashes", ^{
    NSString *const testsAPIKey = @"550e8400-e29b-41d4-a716-446655440000";

    let(amaReporting, ^{ return [KWMock nullMockForProtocol:@protocol(AMAAppMetricaReporting)]; });
    let(crashProcessors, ^{ return [NSMutableArray array]; });
    
    AMACurrentQueueExecutor *__block executor = nil;
    AMACrashProcessor *__block crashProcessor = nil;
    AMAANRWatchdog *__block anrDetectorMock = nil;
    AMACrashReportingStateNotifier *__block stateNotifier = nil;
    AMACrashLoader *__block crashLoader = nil;
    AMACrashReporter *__block crashReporter = nil;
    AMADecodedCrashSerializer *__block serializer = nil;
    AMAAppMetricaCrashes *__block crashes = nil;
    
    AMAStubHostAppStateProvider *__block hostStateProvider = nil;
    
    beforeEach(^{
        executor = [AMACurrentQueueExecutor new];
        hostStateProvider = [[AMAStubHostAppStateProvider alloc] init];
        
        // TODO: replace with factory
        crashProcessor = [AMACrashProcessor nullMock];
        [AMACrashProcessor stub:@selector(alloc) andReturn:crashProcessor];
        [crashProcessor stub:@selector(initWithIgnoredSignals:serializer:crashReporter:extendedProcessors:) andReturn:crashProcessor];
        
        anrDetectorMock = [AMAANRWatchdog nullMock];
        [AMAANRWatchdog stub:@selector(alloc) andReturn:anrDetectorMock];
        [anrDetectorMock stub:@selector(initWithWatchdogInterval:pingInterval:) andReturn:anrDetectorMock];
        
        crashReporter = [AMACrashReporter nullMock];
        [AMACrashReporter stub:@selector(alloc) andReturn:crashReporter];
        [crashReporter stub:@selector(initWithApiKey:errorEnvironment:) andReturn:crashReporter];
        
        serializer = [AMADecodedCrashSerializer nullMock];
        crashLoader = [AMACrashLoader nullMock];
        stateNotifier = [AMACrashReportingStateNotifier nullMock];
        
        crashes = [[AMAAppMetricaCrashes alloc] initWithExecutor:executor
                                                     crashLoader:crashLoader
                                                   stateNotifier:stateNotifier
                                               hostStateProvider:hostStateProvider
                                                      serializer:serializer
                                                   configuration:[AMAAppMetricaCrashesConfiguration new]];
    });

    context(@"Initialization and Singleton", ^{
        it(@"Should correctly initialize shared instance", ^{
            AMAAppMetricaCrashes *firstInstance = [AMAAppMetricaCrashes crashes];
            AMAAppMetricaCrashes *secondInstance = [AMAAppMetricaCrashes crashes];
            [[firstInstance should] equal:secondInstance];
        });
    });

    context(@"Initialization with default configuration", ^{

        let(defaultInitCrashes, ^{ return [AMAAppMetricaCrashes new]; });

        it(@"Should have the default internalConfiguration values when initialized with [AMAAppMetricaCrashes init]", ^{
            AMAAppMetricaCrashesConfiguration *config = [defaultInitCrashes internalConfiguration];

            [[theValue(config.autoCrashTracking) should] beYes];
            [[theValue(config.probablyUnhandledCrashReporting) should] beNo];
            [[config.ignoredCrashSignals should] beNil];
            [[theValue(config.applicationNotRespondingDetection) should] beNo];
            [[theValue(config.applicationNotRespondingWatchdogInterval) should] equal:theValue(4.0)];
            [[theValue(config.applicationNotRespondingPingInterval) should] equal:theValue(0.1)];
        });
    });

    context(@"Configuration Setup", ^{

        __block AMAAppMetricaCrashesConfiguration *initialConfig = nil;
        __block AMAAppMetricaCrashesConfiguration *newConfig = nil;

        beforeEach(^{
            initialConfig = [AMAAppMetricaCrashesConfiguration new];
            newConfig = [AMAAppMetricaCrashesConfiguration new];
            newConfig.autoCrashTracking = NO;
        });

        it(@"Should set a new configuration when not activated", ^{
            [[theValue(crashes.isActivated) should] beNo];
            [crashes setConfiguration:newConfig];
            [[[crashes internalConfiguration] should] equal:newConfig];
        });

        it(@"Should have copied the configuration such that changes to the original do not affect the internal configuration", ^{
            [crashes setConfiguration:initialConfig];
            initialConfig.autoCrashTracking = !initialConfig.autoCrashTracking;
            initialConfig.applicationNotRespondingDetection = !initialConfig.applicationNotRespondingDetection;

            [[[crashes internalConfiguration] shouldNot] equal:initialConfig];
        });
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
        it(@"Should handle nil configuration gracefully", ^{
            initialConfig.applicationNotRespondingWatchdogInterval = 1234; // to make it differ from default
            [crashes setConfiguration:initialConfig];
            [crashes setConfiguration:nil];
            [[crashes.internalConfiguration should] equal:initialConfig];
        });
#pragma clang diagnostic pop
        context(@"When activated", ^{

            beforeEach(^{
                [crashes setConfiguration:initialConfig];
                [crashes activate];
            });

            it(@"Should be activated", ^{
                [[theValue(crashes.isActivated) should] beYes];
            });

            it(@"Should not overwrite the existing configuration once activated", ^{
                [crashes setConfiguration:newConfig];
                [[[crashes internalConfiguration] shouldNot] equal:newConfig];
            });

            it(@"Should retain the initial configuration after trying to set a new one", ^{
                [crashes setConfiguration:newConfig];
                [[[crashes internalConfiguration] should] equal:initialConfig];
            });
        });

        context(@"Activation side-effects", ^{

            context(@"ANR", ^{

                it(@"Should have ANR watchdog enabled if it's part of the configuration", ^{
                    initialConfig.applicationNotRespondingDetection = YES;
                    initialConfig.autoCrashTracking = YES;
                    [crashes setConfiguration:initialConfig];

                    [[anrDetectorMock should] receive:@selector(start)];
                    [crashes activate];
                });

                it(@"Should not have ANR watchdog enabled if auto crash tracking is off, even if ANR detection is on", ^{
                    initialConfig.applicationNotRespondingDetection = YES;
                    initialConfig.autoCrashTracking = NO;
                    [crashes setConfiguration:initialConfig];

                    [[anrDetectorMock shouldNot] receive:@selector(start)];
                    [crashes activate];
                });

                it(@"Should not have ANR watchdog enabled if it's not part of the configuration", ^{
                    initialConfig.applicationNotRespondingDetection = NO;
                    initialConfig.autoCrashTracking = YES;
                    [crashes setConfiguration:initialConfig];

                    [[anrDetectorMock shouldNot] receive:@selector(start)];
                    [crashes activate];
                });

                context(@"When the app transitions between states", ^{

                    beforeEach(^{
                        initialConfig.applicationNotRespondingDetection = YES;
                        initialConfig.autoCrashTracking = YES;
                        [crashes setConfiguration:initialConfig];
                        [crashes activate];
                    });

                    it(@"Should cancel ANR watchdog when app goes to background", ^{
                        [[anrDetectorMock should] receive:@selector(cancel)];
                        [crashes hostStateDidChange:AMAHostAppStateBackground];
                    });

                    it(@"Should start ANR watchdog when app comes to foreground", ^{
                        [[anrDetectorMock should] receive:@selector(start)];
                        [crashes hostStateDidChange:AMAHostAppStateForeground];
                    });
                });
            });

            it(@"Should initialize crash processor with provided ignored signals and serializer", ^{
                initialConfig.ignoredCrashSignals = @[ @SIGABRT, @SIGILL, @SIGSEGV ];
                [[crashProcessor should] receive:@selector(initWithIgnoredSignals:serializer:crashReporter:extendedProcessors:)
                                   withArguments:initialConfig.ignoredCrashSignals, serializer, crashReporter, kw_any()];
                
                [crashes setConfiguration:initialConfig];
                [crashes activate];
                
                [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
                AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
                [AMAAppMetricaCrashes willActivateWithConfiguration:config];
            });

            context(@"CrashLoader Configuration", ^{

                it(@"Should enable required monitoring when autoCrashTracking is disabled", ^{
                    initialConfig.autoCrashTracking = NO;
                    [crashes setConfiguration:initialConfig];

                    [[crashLoader should] receive:@selector(enableRequiredMonitoring)];
                    [[crashLoader shouldNot] receive:@selector(enableCrashLoader)];

                    [crashes activate];
                });

                it(@"Should not enable required monitoring when autoCrashTracking is enabled", ^{
                    initialConfig.autoCrashTracking = YES;
                    [crashes setConfiguration:initialConfig];

                    [[crashLoader shouldNot] receive:@selector(enableRequiredMonitoring)];
                    [[crashLoader should] receive:@selector(enableCrashLoader)];

                    [crashes activate];
                });

                it(@"Should configure the crash loader based on probable unhandled crash reporting", ^{
                    initialConfig.probablyUnhandledCrashReporting = YES;
                    [crashes setConfiguration:initialConfig];

                    [[crashLoader should] receive:@selector(setIsUnhandledCrashDetectingEnabled:)
                                    withArguments:theValue(YES)];

                    [crashes activate];
                });

                it(@"Should update crash context asynchronously", ^{
                    [[AMACrashLoader should] receive:@selector(addCrashContext:)]; // add context check
                    [crashes activate];
                });

                it(@"Should call purgeCrashesDirectory when autoCrashTracking is disabled", ^{
                    initialConfig.autoCrashTracking = NO;
                    [crashes setConfiguration:initialConfig];

                    [[AMACrashLoader should] receive:@selector(purgeCrashesDirectory)];

                    [crashes activate];
                });

                it(@"Should load crash reports after activation when autoCrashTracking is enabled", ^{
                    initialConfig.autoCrashTracking = YES;
                    [crashes setConfiguration:initialConfig];

                    [[crashLoader should] receive:@selector(loadCrashReports)];

                    [crashes activate];
                });

                it(@"Should not load crash reports after activation when autoCrashTracking is disabled", ^{
                    initialConfig.autoCrashTracking = NO;
                    [crashes setConfiguration:initialConfig];

                    [[crashLoader shouldNot] receive:@selector(loadCrashReports)];

                    [crashes activate];
                });
            });

            context(@"StateNotifier", ^{
                it(@"Should notify when activated", ^{
                    [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:)];
                    [crashes activate];
                });

                it(@"Should not notify when configuration is set", ^{
                    [[stateNotifier shouldNot] receive:@selector(notifyWithEnabled:crashedLastLaunch:)];
                    [crashes setConfiguration:initialConfig];
                });
            });
        });

    });

    context(@"Error Reporting", ^{

        NSError *const sampleNSError = [NSError errorWithDomain:@"SampleDomain" code:100 userInfo:nil];
        let(errorRepresentableMock, ^{ return [KWMock mockForProtocol:@protocol(AMAErrorRepresentable)]; });
        let(sampleErrorModel, ^{ return [AMAErrorModel mock]; });

        beforeEach(^{
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
            AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
            [AMAAppMetricaCrashes didActivateWithConfiguration:config];
        });

        it(@"Should not report NSError objects if not activated", ^{
            [[crashReporter shouldNot] receive:@selector(reportNSError:onFailure:)];
            [crashes reportNSError:sampleNSError onFailure:nil];
        });

        it(@"Should not report errors conforming to AMAErrorRepresentable if not activated", ^{
            [[crashReporter shouldNot] receive:@selector(reportError:onFailure:)];
            [crashes reportError:errorRepresentableMock onFailure:nil];
        });

        context(@"After activation", ^{
            beforeEach(^{
                [crashes activate];
                
                AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
                [AMAAppMetricaCrashes willActivateWithConfiguration:config];
            });

            it(@"Should correctly report NSError objects", ^{
                [[crashReporter should] receive:@selector(reportNSError:onFailure:) withArguments:sampleNSError, kw_any()];
                [crashes reportNSError:sampleNSError onFailure:nil];
            });

            it(@"Should correctly report errors conforming to AMAErrorRepresentable", ^{
                [[crashReporter should] receive:@selector(reportError:onFailure:) withArguments:errorRepresentableMock, kw_any()];
                [crashes reportError:errorRepresentableMock onFailure:nil];
            });
        });
    });

    context(@"Error Environment Manipulation", ^{
        
        AMAErrorEnvironment *__block errorEnvironment = nil;
        
        beforeEach(^{
            errorEnvironment = [AMAErrorEnvironment nullMock];
            
            [crashes stub:@selector(errorEnvironment) andReturn:errorEnvironment];
        });

        it(@"Should correctly set the error environment value for a given key", ^{
            [[errorEnvironment should] receive:@selector(addValue:forKey:) withArguments:@"sampleValue", @"sampleKey"];
            [crashes setErrorEnvironmentValue:@"sampleValue" forKey:@"sampleKey"];
        });

        it(@"Should clear the error environment", ^{
            [[errorEnvironment should] receive:@selector(clearEnvironment)];
            [crashes clearErrorEnvironment];
        });
    });
    
    context(@"App Environment Setup", ^{
        AMAEnvironmentContainer *__block appEnvironment = nil;
        
        beforeEach(^{
            appEnvironment = [AMAEnvironmentContainer nullMock];
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
        });

        it(@"Should setup app environment", ^{
            [AMAAppMetricaCrashes setupAppEnvironment:appEnvironment];
            
            [[crashes.appEnvironment should] equal:appEnvironment];
        });
    });

    context(@"CrashLoader Delegate Methods", ^{

        beforeEach(^{
            [crashes activate];
            
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
            AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
            [AMAAppMetricaCrashes willActivateWithConfiguration:config];
        });

        it(@"Should process crash on didLoadCrash callback", ^{
            AMADecodedCrash *sampleCrash = [AMADecodedCrash mock];
            [[crashProcessor should] receive:@selector(processCrash:withError:)];
            [crashes crashLoader:crashLoader didLoadCrash:sampleCrash withError:nil];
        });

        it(@"Should process ANR on didLoadANR callback", ^{
            AMADecodedCrash *sampleANR = [AMADecodedCrash mock];
            [[crashProcessor should] receive:@selector(processANR:withError:)];
            [crashes crashLoader:crashLoader didLoadANR:sampleANR withError:nil];
        });
    });

    context(@"AMAModuleActivationDelegate", ^{

        beforeEach(^{
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
        });
        
        it(@"Should activate crashes on delegate callback", ^{
            AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
            [AMAAppMetricaCrashes willActivateWithConfiguration:config];
            
            [[theValue(crashes.isActivated) should] beYes];
        });
    });

    context(@"AMAEventPollingDelegate", ^{

        beforeEach(^{
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
        });

        //TODO: Add tests for ignored signals filtering
        it(@"Should return events for the previous session", ^{
            NSArray *mockedCrashes = @[[AMADecodedCrash mock], [AMADecodedCrash mock]];
            NSArray *mockedEvents = @[[AMAEventPollingParameters mock], [AMAEventPollingParameters mock]];
            [crashLoader stub:@selector(syncLoadCrashReports) andReturn:mockedCrashes];

            [[serializer should] receive:@selector(eventParametersFromDecodedData:error:)
                               andReturn:mockedEvents[0]
                           withArguments:mockedCrashes[0], KWNull.null];
            [[serializer should] receive:@selector(eventParametersFromDecodedData:error:)
                               andReturn:mockedEvents[1]
                           withArguments:mockedCrashes[1], KWNull.null];

            [[[AMAAppMetricaCrashes pollingEvents] should] equal:mockedEvents];
        });

        it(@"Should handle serialization errors gracefully", ^{
            NSArray *mockedCrashes = @[[AMADecodedCrash mock], [AMADecodedCrash mock]];
            [crashLoader stub:@selector(syncLoadCrashReports) andReturn:mockedCrashes];

            [[serializer should] receive:@selector(eventParametersFromDecodedData:error:)
                               andReturn:nil
                               withCount:mockedCrashes.count];

            [[[AMAAppMetricaCrashes pollingEvents] should] beEmpty];
        });

        it(@"Should return events even if some crashes fail to serialize", ^{
            NSArray *mockedCrashes = @[[AMADecodedCrash mock], [AMADecodedCrash mock]];
            AMAEventPollingParameters *event = [AMAEventPollingParameters mock];
            [crashLoader stub:@selector(syncLoadCrashReports) andReturn:mockedCrashes];

            [serializer stub:@selector(eventParametersFromDecodedData:error:)
                   andReturn:event withArguments:mockedCrashes[0], nil];
            [serializer stub:@selector(eventParametersFromDecodedData:error:)
                   andReturn:nil withArguments:mockedCrashes[1], nil];

            NSArray *events = [AMAAppMetricaCrashes pollingEvents];
            [[events should] haveCountOf:1];
            [[events[0] should] equal:event];
        });
    });

    context(@"AMACrashLoaderDelegate", ^{

        let(sampleError, ^{ return [NSError errorWithDomain:@"test" code:123 userInfo:nil]; });
        let(sampleCrash, ^{ return [AMADecodedCrash mock]; });

        beforeEach(^{
            [crashes activate];
            
            [AMAAppMetricaCrashes stub:@selector(crashes) andReturn:crashes];
            AMAModuleActivationConfiguration *config = [[AMAModuleActivationConfiguration alloc] initWithApiKey:testsAPIKey];
            [AMAAppMetricaCrashes willActivateWithConfiguration:config];
        });

        it(@"Should process a crash when didLoadCrash:withError: is called", ^{
            [[crashProcessor should] receive:@selector(processCrash:withError:)];
            [crashes crashLoader:crashLoader didLoadCrash:sampleCrash withError:sampleError];
        });

        it(@"Should process an ANR when didLoadANR:withError: is called", ^{
            [[crashProcessor should] receive:@selector(processANR:withError:)];
            [crashes crashLoader:crashLoader didLoadANR:sampleCrash withError:sampleError];
        });

        it(@"Should report a foreground unhandled crash", ^{
            [AMAAppMetricaCrashes stub:@selector(errorMessageForProbableUnhandledCrash:) andReturn:
                 @"Detected probable unhandled exception when app was "
                 "in foreground. Exception mean that previous working session have not finished correctly."
            ];
            [[crashProcessor should] receive:@selector(processError:)];
            [crashes crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashForeground];
        });

        context(@"Probable unhandled crash", ^{
            let(mockedError, ^{ return [NSError mock]; });
            
            beforeEach(^{
                [crashes activate];
            });

            it(@"Should report probable unhandled crash with correct error message for foreground crash type", ^{
                NSString *errorMessage = @"Detected probable unhandled exception when app was in foreground. Exception mean that previous working session have not finished correctly.";
                
                KWCaptureSpy *spy = [crashProcessor captureArgument:@selector(processError:) atIndex:0];
                
                [crashes crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashForeground];
                
                NSError *receivedError = spy.argument;
                
                [[theValue(receivedError.code) should] equal:theValue(AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash)];
                [[receivedError.domain should] equal:kAMAAppMetricaInternalErrorDomain];
                [[receivedError.localizedDescription should] equal:errorMessage];
            });
            
            it(@"Should report probable unhandled crash with correct error message for background crash type", ^{
                NSString *errorMessage = @"Detected probable unhandled exception when app was in background. Exception mean that previous working session have not finished correctly.";
                
                KWCaptureSpy *spy = [crashProcessor captureArgument:@selector(processError:) atIndex:0];
                
                [crashes crashLoader:crashLoader didDetectProbableUnhandledCrash:AMAUnhandledCrashBackground];
                
                NSError *receivedError = spy.argument;
                
                [[theValue(receivedError.code) should] equal:theValue(AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash)];
                [[receivedError.domain should] equal:kAMAAppMetricaInternalErrorDomain];
                [[receivedError.localizedDescription should] equal:errorMessage];
            });
        });
    });
    
    context(@"AMAANRWatchdogDelegate", ^{
        it(@"Should report of ANR to crash loader", ^{
            [crashes activate];
            [[crashLoader should] receive:@selector(reportANR)];
            [crashes ANRWatchdogDidDetectANR:[AMAANRWatchdog mock]];
        });
    });
    
    context(@"Crash Reporting State Request", ^{
        __block dispatch_queue_t sampleQueue;
        __block AMACrashReportingStateCompletionBlock sampleBlock;
        
        beforeEach(^{
            sampleQueue = dispatch_queue_create("sample.queue", DISPATCH_QUEUE_SERIAL);
            sampleBlock = ^(NSDictionary * _Nullable state){};
        });
        
        it(@"Should add an observer to the stateNotifier when not activated", ^{
            [[stateNotifier should] receive:@selector(addObserverWithCompletionQueue:completionBlock:) 
                              withArguments:sampleQueue, sampleBlock];
            [[stateNotifier shouldNot] receive:@selector(notifyWithEnabled:crashedLastLaunch:)];
            
            [crashes requestCrashReportingStateWithCompletionQueue:sampleQueue completionBlock:sampleBlock];
        });
        
        it(@"Should add an observer to the stateNotifier and trigger notification when activated", ^{
            [crashes activate];
            
            [crashLoader stub:@selector(crashedLastLaunch) andReturn:@YES];
            
            [[stateNotifier should] receive:@selector(addObserverWithCompletionQueue:completionBlock:) withArguments:sampleQueue, sampleBlock];
            [[stateNotifier should] receive:@selector(notifyWithEnabled:crashedLastLaunch:) withArguments:theValue(YES), @YES];
            
            [crashes requestCrashReportingStateWithCompletionQueue:sampleQueue completionBlock:sampleBlock];
        });
    });
    
    context(@"Handle plugin init finished", ^{
        it(@"Should force update to foreground if started", ^{
            [AMAAppMetrica stub:@selector(isActivated) andReturn:theValue(YES)];
            
            [crashes handlePluginInitFinished];
            
            [[theValue(hostStateProvider.forcedUpdateToForeground) should] beYes];
        });
        it(@"Should force update to foreground if not started", ^{
            [AMAAppMetrica stub:@selector(isActivated) andReturn:theValue(NO)];
            
            [crashes handlePluginInitFinished];
            
            [[theValue(hostStateProvider.forcedUpdateToForeground) should] beNo];
        });
    });
});

SPEC_END
