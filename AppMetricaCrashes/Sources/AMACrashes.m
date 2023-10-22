#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>

#import "AMACrashes.h"
#import "AMACrashes+Private.h"

#import "AMAANRWatchdog.h"
#import "AMACrashContext.h"
#import "AMACrashEventType.h"
#import "AMACrashLoader.h"
#import "AMACrashLogger.h"
#import "AMACrashLogging.h"
#import "AMACrashProcessingReporting.h"
#import "AMACrashProcessor.h"
#import "AMACrashReportingStateNotifier.h"
#import "AMACrashesConfiguration.h"
#import "AMADecodedCrash.h"
#import "AMADecodedCrashSerializer+CustomEventParameters.h"
#import "AMADecodedCrashSerializer.h"
#import "AMAErrorEnvironment.h"
#import "AMAErrorModelFactory.h"

@interface AMACrashes ()

@property (nonatomic, strong) AMACrashProcessor *crashProcessor;
@property (nonatomic, strong) AMACrashReportingStateNotifier *stateNotifier;
@property (nonatomic, strong) id<AMAExecuting> executor;
@property (nonatomic, strong) AMAANRWatchdog *ANRDetector;

//@property (nonatomic, strong) AMAEnvironmentContainer *appEnvironment;
@property (nonatomic, strong) AMAErrorEnvironment *errorEnvironment;

@property (nonatomic, strong, readonly) AMAHostStateProvider *hostStateProvider;
@property (nonatomic, strong, readonly) AMADecodedCrashSerializer *serializer;
@property (nonatomic, strong, readonly) AMAErrorModelFactory *errorModelFactory;

@property (nonatomic, strong) NSMutableSet<id<AMACrashProcessingReporting>> *extendedCrashReporters;

@end

@implementation AMACrashes

@synthesize activated = _activated;

+ (void)load
{
    [AMAAppMetrica addActivationDelegate:self];
    [AMAAppMetrica addEventPollingDelegate:self];
}

+ (void)initialize
{
    if (self == [AMACrashes class]) {
        [AMAAppMetrica.sharedLogConfigurator setupLogWithChannel:AMA_LOG_CHANNEL];
        [AMAAppMetrica.sharedLogConfigurator setChannel:AMA_LOG_CHANNEL enabled:YES];
    }
}

+ (instancetype)crashes
{
    static AMACrashes *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    id<AMAExecuting> executor = [[AMAAsyncExecutor alloc] initWithIdentifier:self];
    AMAUserDefaultsStorage *storage = [[AMAUserDefaultsStorage alloc] init];
    AMAUnhandledCrashDetector *detector = [[AMAUnhandledCrashDetector alloc] initWithStorage:storage executor:executor];

    return [self initWithExecutor:executor
                      crashLoader:[[AMACrashLoader alloc] initWithUnhandledCrashDetector:detector]
                    stateNotifier:[[AMACrashReportingStateNotifier alloc] init]
                hostStateProvider:[[AMAHostStateProvider alloc] init]
                       serializer:[[AMADecodedCrashSerializer alloc] init]
                    configuration:[[AMACrashesConfiguration alloc] init]
                 errorEnvironment:[AMAErrorEnvironment new]
                errorModelFactory:[AMAErrorModelFactory sharedInstance]];
}


- (instancetype)initWithExecutor:(id<AMAExecuting>)executor
                     crashLoader:(AMACrashLoader *)crashLoader
                   stateNotifier:(AMACrashReportingStateNotifier *)stateNotifier
               hostStateProvider:(AMAHostStateProvider *)hostStateProvider
                      serializer:(AMADecodedCrashSerializer *)serializer
                   configuration:(AMACrashesConfiguration *)configuration
                errorEnvironment:(AMAErrorEnvironment *)errorEnvironment
               errorModelFactory:(AMAErrorModelFactory *)errorModelFactory
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _crashProcessor = nil;
        _crashLoader = crashLoader;
        _stateNotifier = stateNotifier;
        _hostStateProvider = [[AMAHostStateProvider alloc] init];
        _hostStateProvider.delegate = self;
        _extendedCrashReporters = [NSMutableSet new];
        _serializer = serializer;
        _internalConfiguration = configuration;
        _errorEnvironment = errorEnvironment;
        _errorModelFactory = errorModelFactory;
    }
    return self;
}

#pragma mark - Public -

- (void)setConfiguration:(AMACrashesConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }

    if (self.isActivated == NO) {
        @synchronized (self) {
            if (self.isActivated == NO) {
                self.internalConfiguration = [configuration copy];
            }
        }
    }
}


- (void)reportNSError:(NSError *)error onFailure:(void (^)(NSError *))onFailure
{
    [self reportNSError:error options:0 onFailure:onFailure];
}

- (void)reportNSError:(NSError *)error
              options:(AMAErrorReportingOptions)options
            onFailure:(void (^)(NSError *))onFailure
{
    if (self.isActivated) {
        [self reportErrorModel:[self.errorModelFactory modelForNSError:error options:options] onFailure:onFailure];
    }
}

- (void)reportError:(id<AMAErrorRepresentable>)error onFailure:(void (^)(NSError *))onFailure
{
    [self reportError:error options:0 onFailure:onFailure];
}

- (void)reportError:(id<AMAErrorRepresentable>)error
            options:(AMAErrorReportingOptions)options
          onFailure:(void (^)(NSError *))onFailure
{
    if (self.isActivated) {
        [self reportErrorModel:[self.errorModelFactory modelForErrorRepresentable:error options:options]
                     onFailure:onFailure];
    }
}

- (void)setErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    [self execute:^{
        [self.errorEnvironment addValue:value forKey:key];
        [self updateCrashContextQuickly:YES];
    }];
}

- (void)clearErrorEnvironment
{
    [self execute:^{
        [self.errorEnvironment clearEnvironment];
        [self updateCrashContextQuickly:YES];
    }];
}

#pragma mark - Internal

- (void)activate
{
    AMACrashesConfiguration *config = nil;
    @synchronized (self) {
        self.activated = YES;
        config = self.internalConfiguration;
    }

    if (config.autoCrashTracking) {
        if (config.applicationNotRespondingDetection) {
            [self enableANRWatchdogWithWatchdogInterval:config.applicationNotRespondingWatchdogInterval
                                           pingInterval:config.applicationNotRespondingPingInterval];
        }
        [self setupCrashProcessorWithIgnoredSignals:config.ignoredCrashSignals];
        [self setupCrashLoaderWithDetection:config.probablyUnhandledCrashReporting];
        [self loadCrashReports];
    }
    else {
        [self setupRequiredMonitoring];
        [self cleanupCrashes];
    }
    [self notifyState];
    [self updateCrashContextAsync];
}

- (void)requestCrashReportingStateWithCompletionQueue:(dispatch_queue_t)completionQueue
                                      completionBlock:(AMACrashReportingStateCompletionBlock)completionBlock
{
    [self.stateNotifier addObserverWithCompletionQueue:completionQueue completionBlock:completionBlock];
    [self notifyState];
}

- (void)enableANRWatchdogWithWatchdogInterval:(NSTimeInterval)watchdogInterval
                                 pingInterval:(NSTimeInterval)pingInterval
{
    [self execute:^{
        [self.ANRDetector cancel];
        self.ANRDetector = [[AMAANRWatchdog alloc] initWithWatchdogInterval:watchdogInterval
                                                               pingInterval:pingInterval];
        self.ANRDetector.delegate = self;
        [self.ANRDetector start];
    }];
}
// FIXME: (belanovich-sy) deadcode, not tested
- (void)addCrashProcessingReporter:(id<AMACrashProcessingReporting>)crashReporter
{
    if (crashReporter != nil) {
        [self execute:^{
            [self.crashProcessor.extendedCrashReporters addObject:crashReporter];
        }];
    }
}

#pragma mark - Properties
/* Setter methods below allow internal write access to properties marked 'readonly' in the +Private extension.
In Objective-C, properties can't be redefined in class extensions. Thus, private setters are used to modify
them while retaining external immutability. Needed for testability. */

- (void)setActivated:(BOOL)activated {
    @synchronized (self) {
        _activated = activated;
    }
}

- (BOOL)isActivated {
    @synchronized (self) {
        return _activated;
    }
}

- (void)setInternalConfiguration:(AMACrashesConfiguration *)internalConfiguration
{
    _internalConfiguration = internalConfiguration;
}

#pragma mark - Private -

- (void)reportErrorModel:(AMAErrorModel *)model onFailure:(void (^)(NSError *))onFailure
{
    __weak typeof(self) weakSelf = self;
    [self execute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.crashProcessor processError:model onFailure:onFailure];
    }];
}

- (void)reportUnhandledException:(AMAPluginErrorDetails *)crash onFailure:(void(^)(NSError *error))onFailure
{
    // FIXME: (glinnik) implement for Plugins
}

#pragma mark - Activation

- (void)setupCrashLoaderWithDetection:(BOOL)enabled
{
    [self.crashLoader setDelegate:self];
    self.crashLoader.isUnhandledCrashDetectingEnabled = enabled;
    [self.crashLoader enableCrashLoader];
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

- (void)cleanupCrashes
{
    [self execute:^{
        [AMACrashLoader purgeCrashesDirectory];
    }];
}

- (void)setupCrashProcessorWithIgnoredSignals:(NSArray<NSNumber *> *)ignoredSignals
{
    [self execute:^{
        self.crashProcessor = [[AMACrashProcessor alloc] initWithIgnoredSignals:ignoredSignals
                                                                     serializer:self.serializer];
    }];
}
// FIXME: (belanovich-sy) deadcode, not tested
- (void)addExtendedCrashReporters
{
    [self execute:^{
        [self.crashProcessor.extendedCrashReporters addObjectsFromArray:[self.extendedCrashReporters allObjects]];
    }];
}

- (void)loadCrashReports
{
    [self execute:^{
        [self.crashLoader loadCrashReports];
    }];
}

- (void)updateCrashContextQuickly:(BOOL)isQuickly
{
    AMAApplicationState *appState = isQuickly ?
        AMAApplicationStateManager.quickApplicationState :
        AMAApplicationStateManager.applicationState;

    NSDictionary *context = @{
        kAMACrashContextAppBuildUIDKey : AMABuildUID.buildUID.stringValue ?: @"",
        kAMACrashContextAppStateKey : appState.dictionaryRepresentation ?: @{},
        kAMACrashContextErrorEnvironmentKey : self.errorEnvironment.currentEnvironment ?: @{},
//        kAMACrashContextAppEnvironmentKey : self.appEnvironment.dictionaryEnvironment ?: @{},
    };

    [AMACrashLoader addCrashContext:context];
}

- (void)notifyState
{
    [self execute:^{
        if (self.isActivated) {
            [self.stateNotifier notifyWithEnabled:self.internalConfiguration.autoCrashTracking
                                crashedLastLaunch:self.crashLoader.crashedLastLaunch];
        }
    }];
}

- (void)execute:(dispatch_block_t)block
{
    [self.executor execute:block];
}

- (id)syncExecute:(id (^)(void))block 
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block id result;

    [self.executor execute:^{
        result = block();
        dispatch_semaphore_signal(sema);
    }];

    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);

    return result;
}

- (NSArray<AMACustomEventParameters *> *)eventsForPreviousSession
{
    __weak typeof(self) weakSelf = self;
    return [self syncExecute:^id{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSArray<AMADecodedCrash *> *crashes = [strongSelf.crashLoader syncLoadCrashReports];
        return [AMACollectionUtilities mapArray:crashes withBlock:^AMACustomEventParameters *(AMADecodedCrash *item) {
            return [strongSelf.serializer eventParametersFromDecodedData:item];
        }];
    }];
}

#pragma mark - AMAModuleActivationDelegate

+ (void)willActivateWithConfiguration:(__unused AMAModuleActivationConfiguration *)configuration
{
    [[[self class] crashes] activate];
}

+ (void)didActivateWithConfiguration:(__unused AMAModuleActivationConfiguration *)configuration
{
}

#pragma mark - AMAEventPollingDelegate

+ (NSArray<AMACustomEventParameters *> *)eventsForPreviousSession 
{
    return [[[self class] crashes] eventsForPreviousSession];
}

#pragma mark - AMACrashLoaderDelegate

// FIXME: (glinnik) this logic is not needed any more, as crashes are now loaded on statrup
- (void)crashLoader:(AMACrashLoader *)crashLoader
       didLoadCrash:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    [self execute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.crashProcessor processCrash:decodedCrash withError:error];
    }];
}

- (void)crashLoader:(AMACrashLoader *)crashLoader
         didLoadANR:(AMADecodedCrash *)decodedCrash
          withError:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    [self execute:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.crashProcessor processANR:decodedCrash withError:error];
    }];
}

- (void)crashLoader:(AMACrashLoader *)crashLoader didDetectProbableUnhandledCrash:(AMAUnhandledCrashType)crashType
{
    if (crashType == AMAUnhandledCrashForeground || crashType == AMAUnhandledCrashBackground) {
        AMALogInfo(@"Reporting probably unhandled crash");
        NSString *errorMessage = [[self class] errorMessageForProbableUnhandledCrash:crashType];
        NSError *error = [AMAErrorUtilities internalErrorWithCode:AMAAppMetricaInternalEventErrorCodeProbableUnhandledCrash
                                                      description:errorMessage];
        [self reportNSError:error onFailure:nil];
    }
}

+ (NSString *)errorMessageForProbableUnhandledCrash:(AMAUnhandledCrashType)crashType
{
    NSString *errorMessage = nil;
    if(crashType == AMAUnhandledCrashForeground) {
        errorMessage = @"Detected probable unhandled exception when app was "
                        "in foreground. Exception mean that previous working session have not finished correctly.";
    }
    else if(crashType == AMAUnhandledCrashBackground) {
        errorMessage = @"Detected probable unhandled exception when app was "
                        "in background. Exception mean that previous working session have not finished correctly.";
    }
    return errorMessage;
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

@end
