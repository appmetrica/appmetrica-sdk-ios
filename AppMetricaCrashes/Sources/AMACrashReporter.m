
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import "AMACrashLogging.h"
#import "AMACrashReporter.h"
#import "AMACrashLoader.h"
#import "AMACrashContext.h"
#import "AMACrashProcessing.h"
#import "AMAAppCrashProcessor.h"
#import "AMAGenericCrashProcessor.h"
#import "AMASymbolsManager.h"
#import "AMADecodedCrash.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMALibrarySymbolsProvider.h"
#import "AMAANRWatchdog.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashLogger.h"

NSString *const kAMAForegroundUnhandledExceptionReason = @"Detected probable unhandled exception when app was "
    "in foreground. Exception mean that previous working session have not finished correctly.";
NSString *const kAMABackgroundUnhandedExceptionReason = @"Detected probable unhandled exception when app was "
    "in background. Exception mean that previous working session have not finished correctly.";

//TODO: Crashes fixing
@interface AMACrashReporter ()

@property (nonatomic, strong) NSMutableArray<id<AMACrashProcessing>> *crashProcessors;
@property (nonatomic, strong) AMACrashLoader *crashLoader;
@property (nonatomic, strong) AMACrashReportingStateNotifier *stateNotifier;
@property (nonatomic, strong) id<AMAExecuting> executor;
@property (nonatomic, strong) AMAANRWatchdog *ANRDetector;

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL configurationSet;

@property (nonatomic, strong) AMAEnvironmentContainer *appEnvironment;
@property (nonatomic, strong) AMAEnvironmentContainer *errorEnvironment;

@property (nonatomic, strong, readonly) AMAHostStateProvider *hostStateProvider;

@property (nonatomic, strong) NSMutableSet<id<AMACrashProcessingReporting>> *extendedCrashReporters;

@end

@implementation AMACrashReporter

//+ (void)load
//{
//    [AMAAppMetrica registerModule:self];
//}

+ (void)initialize
{
    if (self == [AMACrashReporter class]) {
        [AMAAppMetrica.sharedLogConfigurator setupLogWithChannel:AMA_LOG_CHANNEL];
        [AMAAppMetrica.sharedLogConfigurator setChannel:AMA_LOG_CHANNEL enabled:YES];
    }
}

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
{
    AMAUnhandledCrashDetector *detector =
        [[AMAUnhandledCrashDetector alloc] initWithStorage:[[AMAUserDefaultsStorage alloc] init]
                                                  executor:executor];
    AMACrashLoader *crashLoader = [[AMACrashLoader alloc] initWithUnhandledCrashDetector:detector];

    return [self initWithExecutor:executor
                      crashLoader:crashLoader
                    stateNotifier:[[AMACrashReportingStateNotifier alloc] init]];
}

- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                     crashLoader:(AMACrashLoader *)crashLoader
                   stateNotifier:(AMACrashReportingStateNotifier *)stateNotifier
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _crashProcessors = [NSMutableArray new];
        _crashLoader = crashLoader;
        _stateNotifier = stateNotifier;
        _hostStateProvider = [[AMAHostStateProvider alloc] init];
        _hostStateProvider.delegate = self;
        _extendedCrashReporters = [NSMutableSet new];
    }
    return self;
}

- (void)setupCrashLoader
{
    [self.crashLoader setDelegate:self];
    [self.crashLoader enableCrashLoader];
//    if ([AMAMetricaConfiguration sharedInstance].instant.dynamicLibraryCrashHookEnabled) {
//        [self.crashLoader enableSwapOfCxaThrow];
//    }
//    [[AMAMetricaConfiguration sharedInstance].instant addAMAObserver:self];
}

- (void)setupRequiredMonitoring
{
    [self.crashLoader enableRequiredMonitoring];
}

- (void)updateCrashContextAsync
{
    [self execute:^{
        [self updateCrashContextQuickly:NO];
    }];
}

- (void)registerCrashProcessorForMetrica
{
    [self execute:^{
//        AMACrashMatchingRule *rule =
//            [[AMACrashMatchingRule alloc] initWithClasses:[AMALibrarySymbolsProvider classes]
//                                            classPrefixes:nil
//                                       dynamicBinaryNames:[AMALibrarySymbolsProvider dynamicBinaries]];
//        [[self class] registerSymbolsForApiKey:kAMAMetricaLibraryApiKey rule:rule];
    }];
}

- (void)cleanupSymbolsCache
{
    [self execute:^{
        [AMASymbolsManager cleanup];
    }];
}

- (void)cleanupCrashes
{
    [self execute:^{
        [AMACrashLoader purgeCrashesDirectory];
    }];
}

- (void)setConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    self.enabled = configuration.crashReporting;
    if (self.enabled) {
//        if (configuration.applicationNotRespondingDetection) {
//            [self enableANRWatchdogWithWatchdogInterval:configuration.applicationNotRespondingWatchdogInterval
//                                           pingInterval:configuration.applicationNotRespondingPingInterval];
//        }
        [self registerCrashProcessorForMetrica];
        [self addAppCrashProcessor];
        [self addRegisteredCrashProcessors];
        [self setupCrashLoader];
        [self notifyConfigurationIsSet];
        [self loadCrashReports];
    }
    else {
        [self setupRequiredMonitoring];
        [self notifyConfigurationIsSet];
        [self cleanupCrashes];
    }
    [self cleanupSymbolsCache];
}

- (void)enableANRWatchdogWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                                 pingInterval:(NSTimeInterval)pingInterval
{
    if (self.enabled) {
        [self execute:^{
            [self.ANRDetector cancel];
            self.ANRDetector = [[AMAANRWatchdog alloc] initWithWatchdogInterval:watchdogInterval
                                                                   pingInterval:pingInterval];
            self.ANRDetector.delegate = self;
            [self.ANRDetector start];
        }];
    }
    else {
        [AMACrashLogger logCrashDetectingNotEnabled:@"Can't activate ANR watchdog"];
    }
}

- (void)addAppCrashProcessor
{
    [self execute:^{
        NSArray<NSNumber *> *ignoredCrashSignals = @[];//[AMAMetricaConfiguration sharedInstance].inMemory.ignoredCrashSignals;
        [self addCrashProcessor:[[AMAAppCrashProcessor alloc] initWithIgnoredSignals:ignoredCrashSignals]];
    }];
}

- (void)addCrashProcessingReporter:(id<AMACrashProcessingReporting>)crashReporter
{
    if (crashReporter != nil) {
        [self execute:^{
            for (id<AMACrashProcessing> crashProcessor in self.crashProcessors) {
                [crashProcessor.extendedCrashReporters addObject:crashReporter];
            }
            [self.extendedCrashReporters addObject:crashReporter];
        }];
    }
}

- (void)addRegisteredCrashProcessors
{
    [self execute:^{
        NSArray *apiKeys = [AMASymbolsManager registeredApiKeys];
        for (NSString *apiKey in apiKeys) {
            AMAGenericCrashProcessor *crashProcessor = [[AMAGenericCrashProcessor alloc] initWithApiKey:apiKey];
            [self addCrashProcessor:crashProcessor];
        }
    }];
}

- (void)addCrashProcessor:(id<AMACrashProcessing>)crashProcessor
{
    if (crashProcessor != nil) {
        [self addExtendedCrashReporters:crashProcessor];
        [self execute:^{
            [self.crashProcessors addObject:crashProcessor];
        }];
    }
}

- (void)addExtendedCrashReporters:(id<AMACrashProcessing>)crashProcessor
{
    [self execute:^{
        [crashProcessor.extendedCrashReporters addObjectsFromArray:[self.extendedCrashReporters allObjects]];
    }];
}

- (void)loadCrashReports
{
    [self execute:^{
        [self.crashLoader loadCrashReports];
    }];
}

- (void)quickSetupEnvironment
{
//    self.errorEnvironment = [AMAReporterStoragesContainer sharedInstance].errorEnvironment;
    [self updateCrashContextQuickly:YES];
//    [self.errorEnvironment addObserver:self withBlock:^(AMACrashReporter *observer, AMAEnvironmentContainer *e) {
//        [observer updateCrashContextAsync];
//    }];
}

- (void)setupEnvironmentWithReporterStateStorage:(AMAReporterStateStorage *)reporterStateStorage
{
    [self execute:^{
//        [self.appEnvironment removeObserver:self];
//        [self.errorEnvironment removeObserver:self];

//        self.appEnvironment = reporterStateStorage.appEnvironment;
//        self.errorEnvironment = reporterStateStorage.errorEnvironment;

        [self updateCrashContextQuickly:NO];

//        [self.errorEnvironment addObserver:self withBlock:^(AMACrashReporter *observer, AMAEnvironmentContainer *e) {
//            [observer updateCrashContextAsync];
//        }];
//        [self.appEnvironment addObserver:self withBlock:^(AMACrashReporter *observer, AMAEnvironmentContainer *e) {
//            [observer updateCrashContextAsync];
//        }];
    }];
}

- (void)updateCrashContextQuickly:(BOOL)isQuickly
{
//    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
    AMAApplicationState *appState = isQuickly ?
        AMAApplicationStateManager.quickApplicationState :
        AMAApplicationStateManager.applicationState;

//    self.crashLoader.isUnhandledCrashDetectingEnabled = configuration.inMemory.probablyUnhandledCrashDetectingEnabled;
//    NSDictionary *context = @{
//        kAMACrashContextAppBuildUIDKey : configuration.inMemory.appBuildUID.stringValue ?: @"",
//        kAMACrashContextAppStateKey : [appState dictionaryRepresentation] ?: @{},
//        kAMACrashContextErrorEnvironmentKey : self.errorEnvironment.dictionaryEnvironment ?: @{},
//        kAMACrashContextAppEnvironmentKey : self.appEnvironment.dictionaryEnvironment ?: @{},
//    };
//
//    [AMACrashLoader addCrashContext:context];
}

- (void)requestCrashReportingStateWithCompletionQueue:(dispatch_queue_t)completionQueue
                                      completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock
{
    [self.stateNotifier addObserverWithCompletionQueue:completionQueue completionBlock:completionBlock];
    [self notifyState];
}

- (void)notifyConfigurationIsSet
{
    [self execute:^{
        self.configurationSet = YES;
    }];
    [self notifyState];
}

- (void)notifyState
{
    [self execute:^{
        if (self.configurationSet) {
            [self.stateNotifier notifyWithEnabled:self.enabled crashedLastLaunch:self.crashLoader.crashedLastLaunch];
        }
    }];
}

- (void)execute:(dispatch_block_t)block
{
    [self.executor execute:block];
}

#pragma mark - Metrica Configuration update

- (void)handleConfigurationUpdate
{
    [self updateCrashContextAsync];
}

#pragma mark - AMACrashLoaderDelegate

- (void)crashLoader:(AMACrashLoader *)crashLoader
       didLoadCrash:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    [self execute:^{
        if (error != nil) {
            [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        }
        else {
            for (id<AMACrashProcessing> crashProcessor in self.crashProcessors) {
                NSString *transactionID = [crashProcessor identifier];
//                [AMACrashSafeTransactor processTransactionWithID:transactionID name:@"CrashProcessing" transaction:^{
//                    [crashProcessor processCrash:decodedCrash];
//                }];
            }
        }
    }];
}

- (void)crashLoader:(AMACrashLoader *)crashLoader
         didLoadANR:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    [self execute:^{
        if (error != nil) {
            [self reportCrashReportErrorToMetrica:decodedCrash withError:error];
        }
        else {
            for (id<AMACrashProcessing> crashProcessor in self.crashProcessors) {
                NSString *transactionID = [crashProcessor identifier];
//                [AMACrashSafeTransactor processTransactionWithID:transactionID name:@"ANRProcessing" transaction:^{
//                    [crashProcessor processANR:decodedCrash];
//                }];
            }
        }
    }];
}

- (void)reportCrashReportErrorToMetrica:(AMADecodedCrash *)decodedCrash withError:(NSError *)error
{
    switch (error.code) {
        case AMAAppMetricaEventErrorCodeInvalidName:
//            [[AMAAppMetrica sharedInternalEventsReporter] reportCorruptedCrashReportWithError:error];
            break;
        case AMAAppMetricaInternalEventErrorCodeRecrash:
//            [[AMAAppMetrica sharedInternalEventsReporter] reportRecrashWithError:error];
            break;
        case AMAAppMetricaInternalEventErrorCodeUnsupportedReportVersion:
//            [[AMAAppMetrica sharedInternalEventsReporter] reportUnsupportedCrashReportVersionWithError:error];
            break;
        default:
            break;
    }
}

- (void)crashLoader:(AMACrashLoader *)crashLoader didDetectProbableUnhandledCrash:(AMAUnhandledCrashType)crashType
{
    [self execute:^{
        if (crashType == AMAUnhandledCrashForeground || crashType == AMAUnhandledCrashBackground) {
            AMALogInfo(@"Reporting probably unhandled crash");
            NSString *errorMessage = [[self class] errorMessageForProbableUnhandledCrash:crashType];
            for (id<AMACrashProcessing> crashProcessor in self.crashProcessors) {
                [crashProcessor processError:errorMessage exception:nil];
            }
        }
    }];
}

+ (NSString *)errorMessageForProbableUnhandledCrash:(AMAUnhandledCrashType)crashType
{
    NSString *errorMessage = nil;
    if(crashType == AMAUnhandledCrashForeground) {
        errorMessage = kAMAForegroundUnhandledExceptionReason;
    }
    else if(crashType == AMAUnhandledCrashBackground) {
        errorMessage = kAMABackgroundUnhandedExceptionReason;
    }
    return errorMessage;
}

+ (void)registerSymbolsForApiKey:(NSString *)apiKey rule:(AMACrashMatchingRule *)rule
{
     NSString *transactionID = [AMAGenericCrashProcessor identifierForApiKey:apiKey];
//     [AMACrashSafeTransactor processTransactionWithID:transactionID name:@"SymbolsRegistration" transaction:^{
//         [AMASymbolsManager registerSymbolsForApiKey:apiKey rule:rule];
//     }];
}

#pragma mark - AMAANRWatchdogDelegate

- (void)ANRWatchdogDidDetectANR:(AMAANRWatchdog *)detector
{
    [self execute:^{
        AMALogInfo(@"Reporting of ANR crash.");
        [self.crashLoader reportANR];
    }];
}

#pragma mark - AMAHostStateProviderDelegate

- (void)hostStateDidChange:(AMAHostAppState)hostState
{
    switch (hostState) {
        case AMAHostAppStateBackground:
            [self.ANRDetector cancel];
            break;
        case AMAHostAppStateForeground:
            [self.ANRDetector start];
            break;
        default:
            break;
    }
}

#pragma mark - AMAInstantFeaturesObserver

//- (void)instantFeaturesConfigurationDidUpdate:(AMAInstantFeaturesConfiguration *)configuration
//{
//    if (configuration.dynamicLibraryCrashHookEnabled) {
//        [self.crashLoader enableSwapOfCxaThrow];
//    }
//}

@end
