
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMACore.h"
#if !TARGET_OS_TV
#import <WebKit/WebKit.h>
#endif
#import "AMAAppMetricaImpl.h"
#import "AMAAppMetrica.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAMetricaParametersScanner.h"
#import "AMASharedReporterProvider.h"
#import "AMAErrorLogger.h"
#import "AMADeepLinkController.h"
#import "AMAInternalEventsReporter.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAUserProfile.h"
#import "AMARevenueInfo.h"
#import "AMADatabaseQueueProvider.h"
#import "AMALocationManager.h"
#import "AMAReporterStoragesContainer.h"
#import "AMAEnvironmentContainer.h"
#import "AMAUUIDProvider.h"
#import "AMAAppMetricaPlugins.h"
#import "AMAAppMetricaPluginsImpl.h"
#import "AMAAdRevenueInfo.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAAdProvider.h"

static NSMutableSet<Class<AMAModuleActivationDelegate>> *activationDelegates = nil;
static NSMutableSet<Class<AMAEventFlushableDelegate>> *eventFlushableDelegates = nil;

static id<AMAAdProviding> adProvider = nil;
static NSMutableSet<id<AMAExtendedStartupObserving>> *startupObservers = nil;
static NSMutableSet<id<AMAReporterStorageControlling>> *reporterStorageControllers = nil;

@implementation AMAAppMetrica

+ (void)initialize
{
    if (self == [AMAAppMetrica class]) {
        [[self sharedLogConfigurator] setupLogWithChannel:AMA_LOG_CHANNEL];
        [[self class] setLogs:NO];
    }
}

#pragma mark - Core Extension -

+ (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activationDelegates = [[NSMutableSet alloc] init];
    });
    @synchronized(self) {
        [activationDelegates addObject:delegate];
    }
}

+ (void)addEventFlushableDelegate:(Class<AMAEventFlushableDelegate>)delegate
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        eventFlushableDelegates = [[NSMutableSet alloc] init];
    });
    @synchronized(self) {
        [eventFlushableDelegates addObject:delegate];
    }
}

+ (void)activateDelegates:(AMAAppMetricaConfiguration *)configuration
{
    @synchronized(self) {
        __auto_type *moduleConfig = [[AMAModuleActivationConfiguration alloc] initWithApiKey:configuration.apiKey
                                                                                  appVersion:configuration.appVersion
                                                                              appBuildNumber:configuration.appBuildNumber];
        for (Class<AMAModuleActivationDelegate> delegate in activationDelegates) {
            [delegate didActivateWithConfiguration:moduleConfig];
        }
    }
}

+ (void)registerExternalService:(AMAServiceConfiguration *)configuration
{
    @synchronized(self) {
        if (configuration.startupObserver != nil) {
            [[self class] addStartupObserver:configuration.startupObserver];
        }
        if (configuration.reporterStorageController != nil) {
            [[self class] addReporterStorageController:configuration.reporterStorageController];
        }
    }
}

+ (void)addStartupObserver:(id<AMAExtendedStartupObserving>)observer
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        startupObservers = [[NSMutableSet alloc] init];
    });
    @synchronized(self) {
        __weak __typeof(id<AMAExtendedStartupObserving>) weakObserver = observer;
        [startupObservers addObject:weakObserver];
    }
}

+ (void)addReporterStorageController:(id<AMAReporterStorageControlling>)controller
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reporterStorageControllers = [[NSMutableSet alloc] init];
    });
    @synchronized(self) {
        __weak __typeof(id<AMAReporterStorageControlling>) weakController = controller;
        [reporterStorageControllers addObject:weakController];
    }
}

+ (void)registerAdProvider:(id<AMAAdProviding>)provider
{
    @synchronized(self) {
        adProvider = provider;
    }
}

+ (void)setupExternalServices
{
    @synchronized (self) {
        if ([AMAMetricaConfiguration sharedInstance].inMemory.externalServicesConfigured) {
            return;
        }
        if (startupObservers != nil) {
            [[self sharedImpl] setExtendedStartupObservers:startupObservers];
        }
        if (reporterStorageControllers != nil) {
            [[self sharedImpl] setExtendedReporterStorageControllers:reporterStorageControllers];
        }
        if (adProvider != nil) {
            [[AMAAdProvider sharedInstance] setupAdProvider:adProvider];
        }
        [[AMAMetricaConfiguration sharedInstance].inMemory markExternalServicesConfigured];
    }
}

+ (void)setSessionExtras:(nullable NSData *)data forKey:(NSString *)key
{
    [[self sharedImpl] setSessionExtras:data forKey:key];
}

+ (void)clearSessionExtra
{
    [[self sharedImpl] clearSessionExtra];
}

+ (BOOL)isAPIKeyValid:(NSString *)apiKey
{
    return [AMAIdentifierValidator isValidUUIDKey:apiKey];
}

+ (BOOL)isAppMetricaStarted
{
    @synchronized(self) {
        return [AMAMetricaConfiguration sharedInstance].inMemory.appMetricaStarted;
    }
}

+ (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey
{
    @synchronized(self) {
        return [self isMetricaImplCreated] && [[self sharedImpl] isReporterCreatedForAPIKey:apiKey];
    }
}

+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
                environment:(nullable NSDictionary *)environment
                  onFailure:(nullable void (^)(NSError *error))onFailure
{
    [self reportEventWithType:eventType
                         name:name
                        value:value
                  environment:environment
                       extras:nil
                    onFailure:onFailure];
}

+ (void)reportEventWithParameters:(AMACustomEventParameters *)parameters
                        onFailure:(void (^)(NSError * _Nonnull))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportEventWithParameters:parameters onFailure:onFailure];
    }
}

+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
                environment:(nullable NSDictionary *)environment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportEventWithType:eventType
                                          name:name
                                         value:value
                                   environment:environment
                                        extras:extras
                                     onFailure:onFailure];
    }
}

+ (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                          gZipped:(BOOL)gZipped
                      environment:(nullable NSDictionary *)environment
                           extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportBinaryEventWithType:eventType
                                                data:data
                                             gZipped:gZipped
                                         environment:environment
                                              extras:extras
                                           onFailure:onFailure];
    }
}

+ (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                       gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
                    environment:(nullable NSDictionary *)environment
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                      onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportFileEventWithType:eventType
                                              data:data
                                          fileName:fileName
                                           gZipped:gZipped
                                         encrypted:encrypted
                                         truncated:truncated
                                       environment:environment
                                            extras:extras
                                         onFailure:onFailure];
    }
}


#pragma mark - Handle Configuration -

+ (void)importLogConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    [self setLogs:configuration.logs];
    [[self sharedExecutor] execute:^{
        [AMADatabaseQueueProvider sharedInstance].logsEnabled = configuration.logs;
    }];
}

+ (void)importDataSendingEnabledConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMADataSendingRestriction restriction = AMADataSendingRestrictionUndefined;
    if (configuration.dataSendingEnabledState != nil) {
        restriction = [configuration.dataSendingEnabledState boolValue]
            ? AMADataSendingRestrictionAllowed
            : AMADataSendingRestrictionForbidden;
    }

    AMADataSendingRestrictionController *controller = [AMADataSendingRestrictionController sharedInstance];
    [controller setMainApiKey:configuration.apiKey];
    [controller setMainApiKeyRestriction:restriction];
}

+ (void)importLocationConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    if (configuration.locationTrackingState != nil) {
        [self setLocationTracking:configuration.locationTracking];
    }
    if (configuration.location != nil) {
        [self setLocation:configuration.location];
    }
    [self setAccurateLocationTracking:configuration.accurateLocationTracking];
}

+ (void)importReporterConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration sharedInstance];
    AMAMutableReporterConfiguration *appConfiguration =
        [metricaConfiguration.appConfiguration mutableCopy];
    appConfiguration.apiKey = configuration.apiKey;
    appConfiguration.sessionTimeout = configuration.sessionTimeout;
    appConfiguration.maxReportsCount = configuration.maxReportsCount;
    appConfiguration.maxReportsInDatabaseCount = configuration.maxReportsInDatabaseCount;
    appConfiguration.dispatchPeriod = configuration.dispatchPeriod;
    appConfiguration.logs = configuration.logs;
    appConfiguration.dataSendingEnabled = configuration.dataSendingEnabled;
    metricaConfiguration.appConfiguration = [appConfiguration copy];

    metricaConfiguration.inMemory.handleFirstActivationAsUpdate = configuration.handleFirstActivationAsUpdate;
    metricaConfiguration.inMemory.handleActivationAsSessionStart = configuration.handleActivationAsSessionStart;
    metricaConfiguration.inMemory.sessionsAutoTracking = configuration.sessionsAutoTracking;
}

+ (void)importCustomVersionConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    if (configuration.appVersion.length != 0) {
        [AMAMetricaConfiguration sharedInstance].inMemory.appVersion = configuration.appVersion;
    }
    if (configuration.appBuildNumber.length != 0) {
        uint32_t uintBuildNumber = 0;
        BOOL isNewValueValid = [AMAMetricaParametersScanner scanAppBuildNumber:&uintBuildNumber
                                                                      inString:configuration.appBuildNumber];
        if (isNewValueValid) {
            [AMAMetricaConfiguration sharedInstance].inMemory.appBuildNumber = uintBuildNumber;
            [AMAMetricaConfiguration sharedInstance].inMemory.appBuildNumberString = configuration.appBuildNumber;
        } else {
            [AMAErrorLogger logInvalidCustomAppBuildNumberError];
        }
    }
}

+ (void)importCrashReportingConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMAMetricaConfiguration *internalConfiguration = [AMAMetricaConfiguration sharedInstance];
    internalConfiguration.inMemory.reportCrashesEnabled = configuration.crashReporting;
    internalConfiguration.inMemory.probablyUnhandledCrashDetectingEnabled = configuration.probablyUnhandledCrashReporting;
    internalConfiguration.inMemory.ignoredCrashSignals = configuration.ignoredCrashSignals;
}

+ (void)importConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }

    [self importLogConfiguration:configuration];

    AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration sharedInstance];

    [self importLocationConfiguration:configuration];
    [self importDataSendingEnabledConfiguration:configuration];

    metricaConfiguration.persistent.userStartupHosts = configuration.customHosts;
    [[self sharedImpl] setPreloadInfo:configuration.preloadInfo];

    [self importReporterConfiguration:configuration];
    [self importCustomVersionConfiguration:configuration];
    [self importCrashReportingConfiguration:configuration];

    [self handleConfigurationUpdate];
}

+ (void)handleConfigurationUpdate
{
    [[self sharedImpl] handleConfigurationUpdate];
}

#pragma mark - Public API -

+ (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    @synchronized (self) {
        NSString *apiKey = configuration.apiKey;

        if ([self isAppMetricaStarted]) {
            [AMAErrorLogger logMetricaAlreadyStartedError];
            return;
        }
        if ([self isAPIKeyValid:apiKey] == NO) {
            [AMAErrorLogger logInvalidApiKeyError:apiKey];
            return;
        }
        if ([self isReporterCreatedForAPIKey:apiKey]) {
            [AMAErrorLogger logMetricaActivationWithAlreadyPresentedKeyError];
            return;
        }
        [[self class] setupExternalServices];
        [self importConfiguration:configuration];
        [[self sharedImpl] activateWithConfiguration:configuration];
        [[AMAMetricaConfiguration sharedInstance].inMemory markAppMetricaStarted];
        [[self class] activateDelegates:configuration];
    }
}

+ (void)reportEvent:(NSString *)message onFailure:(void (^)(NSError *error))onFailure
{
    [[self class] reportEvent:message parameters:nil onFailure:onFailure];
}

+ (void)reportEvent:(NSString *)message
         parameters:(NSDictionary *)params
          onFailure:(void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportEvent:[message copy] parameters:[params copy] onFailure:onFailure];
    }
}

+ (void)reportUserProfile:(AMAUserProfile *)userProfile onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportUserProfile:[userProfile copy] onFailure:onFailure];
    }
}

+ (void)reportRevenue:(AMARevenueInfo *)revenueInfo onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportRevenue:revenueInfo onFailure:onFailure];
    }
}

+ (void)reportECommerce:(AMAECommerce *)eCommerce onFailure:(void (^)(NSError *))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportECommerce:eCommerce onFailure:onFailure];
    }
}

+ (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenue onFailure:(void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportAdRevenue:adRevenue onFailure:onFailure];
    }
}

#if !TARGET_OS_TV
+ (void)setupWebViewReporting:(id<AMAJSControlling>)controller
                    onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] setupWebViewReporting:controller];
    }
}
#endif

+ (void)setUserProfileID:(NSString *)userProfileID
{
    [[self sharedImpl] setUserProfileID:[userProfileID copy]];
}

+ (void)setLogs:(BOOL)enabled
{
    [[self sharedLogConfigurator] setChannel:AMA_LOG_CHANNEL enabled:enabled];
}

+ (void)setDataSendingEnabled:(BOOL)enabled
{
    AMADataSendingRestriction restriction = enabled
        ? AMADataSendingRestrictionAllowed
        : AMADataSendingRestrictionForbidden;
    [[AMADataSendingRestrictionController sharedInstance] setMainApiKeyRestriction:restriction];
}

#if TARGET_OS_IOS
+ (void)sendMockVisit:(CLVisit *)visit
{
    [[AMALocationManager sharedManager] sendMockVisit:visit];
}
# endif

+ (void)setLocation:(CLLocation *)location
{
    [[AMALocationManager sharedManager] setLocation:location];
    AMALogInfo(@"Set location %@", location);
}

+ (void)setLocationTracking:(BOOL)enabled
{
    [[AMALocationManager sharedManager] setTrackLocationEnabled:enabled];
    AMALogInfo(@"Set track location enabled %i", enabled);
}

+ (NSString *)libraryVersion
{
    return [AMAPlatformDescription SDKVersionName];
}

+ (void)handleOpenURL:(NSURL *)url
{
    if ([self isAppMetricaStarted] == NO) {
        AMALogWarn(@"Metrica is not started");
        return;
    }
    [[self sharedImpl] reportUrl:url ofType:kAMADLControllerUrlTypeOpen isAuto:NO];
}

+ (void)reportReferralUrl:(NSURL *)url
{
    if ([self isAppMetricaStarted] == NO) {
        AMALogWarn(@"Metrica is not started");
        return;
    }
    [[self sharedImpl] reportUrl:url ofType:kAMADLControllerUrlTypeReferral isAuto:NO];
}

+ (void)setErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    @synchronized(self) {
        if ([self isMetricaImplCreated]) {
            [[self sharedImpl] setErrorEnvironmentValue:value forKey:key];
        }
        else {
            [AMAAppMetricaImpl syncSetErrorEnvironmentValue:value forKey:key];
        }
    }
}

+ (void)setAppEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    [[self sharedImpl] setAppEnvironmentValue:value forKey:key];
}

+ (void)clearAppEnvironment
{
    [[self sharedImpl] clearAppEnvironment];
}

+ (void)sendEventsBuffer
{
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    [[self sharedImpl] sendEventsBuffer];

    @synchronized(self) {
        for (Class<AMAEventFlushableDelegate> delegate in eventFlushableDelegates) {
            [delegate sendEventsBuffer];
        }
    }
}

+ (void)pauseSession
{
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    if ([AMAMetricaConfiguration sharedInstance].inMemory.sessionsAutoTracking) {
        [AMAErrorLogger logMetricaActivationWithAutomaticSessionsTracking];
        return;
    }
    [[self sharedImpl] pauseSession];
}

+ (void)resumeSession
{
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    if ([AMAMetricaConfiguration sharedInstance].inMemory.sessionsAutoTracking) {
        [AMAErrorLogger logMetricaActivationWithAutomaticSessionsTracking];
        return;
    }
    [[self sharedImpl] resumeSession];
}

+ (void)setAccurateLocationTracking:(BOOL)enabled
{
    [AMALocationManager sharedManager].accurateLocationEnabled = enabled;
}

+ (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates
{
    [AMALocationManager sharedManager].allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
}

+ (void)activateReporterWithConfiguration:(AMAReporterConfiguration *)configuration
{
    if ([self isAPIKeyValid:configuration.apiKey] == NO) {
        [AMAErrorLogger logInvalidApiKeyError:configuration.apiKey];
        return;
    }

    @synchronized (self) {
        if ([self isReporterCreatedForAPIKey:configuration.apiKey]) {
            [AMAErrorLogger logMetricaActivationWithAlreadyPresentedKeyError];
        }
        else {
            [[self class] setupExternalServices];
            AMADataSendingRestriction restriction = AMADataSendingRestrictionUndefined;
            if (configuration.dataSendingEnabledState != nil) {
                restriction = [configuration.dataSendingEnabledState boolValue]
                    ? AMADataSendingRestrictionAllowed
                    : AMADataSendingRestrictionForbidden;
            }
            [[AMADataSendingRestrictionController sharedInstance] setReporterRestriction:restriction
                                                                               forApiKey:configuration.apiKey];

            [[AMAMetricaConfiguration sharedInstance] setConfiguration:configuration];
            [self handleConfigurationUpdate];
            [[self sharedImpl] manualReporterForConfiguration:configuration];
        }
    }
}

+ (id<AMAAppMetricaReporting>)reporterForApiKey:(NSString *)apiKey
{
    return [self extendedReporterForApiKey:apiKey];
}

+ (id<AMAAppMetricaExtendedReporting>)extendedReporterForApiKey:(NSString *)apiKey
{
    if ([self isAPIKeyValid:apiKey] == NO) {
        [AMAErrorLogger logInvalidApiKeyError:apiKey];
        return nil;
    }

    @synchronized (self) {
        if ([self isReporterCreatedForAPIKey:apiKey] == NO) {
            [[AMADataSendingRestrictionController sharedInstance] setReporterRestriction:AMADataSendingRestrictionUndefined
                                                                              forApiKey:apiKey];
        }
        AMAReporterConfiguration *configuration = [[AMAReporterConfiguration alloc] initWithApiKey:apiKey];
        id<AMAAppMetricaExtendedReporting> reporter = [[self sharedImpl] manualReporterForConfiguration:configuration];
        return reporter;
    }
}

+ (void)requestAppMetricaDeviceIDWithCompletionQueue:(nullable dispatch_queue_t)queue
                                     completionBlock:(AMAAppMetricaDeviceIDRetrievingBlock)block {
    __auto_type handleErrorBlock = ^(NSError *error) {
        if (block != nil) { dispatch_async(queue, ^{ block(nil, error); }); }
    };
    
    if ([self isAppMetricaStartedWithLogging:handleErrorBlock]) {
        AMAIdentifiersCompletionBlock identifiersCompletionBlock = ^(NSDictionary * _Nullable identifiers,
                                                                     NSError * _Nullable error) {
            NSString *deviceIDHash = identifiers[kAMADeviceIDHashKey];
            block(deviceIDHash, error);
        };
        [self requestStartupIdentifiersWithCompletionQueue:queue
                                           completionBlock:identifiersCompletionBlock];
    }
}

+ (void)requestStartupIdentifiersWithCompletionQueue:(nullable dispatch_queue_t)queue
                                     completionBlock:(AMAIdentifiersCompletionBlock)block
{
    [[self sharedImpl] requestStartupIdentifiersWithCompletionQueue:queue
                                                    completionBlock:block
                                                      notifyOnError:YES];
}

+ (void)requestStartupIdentifiersWithKeys:(NSArray<NSString *> *)keys
                          completionQueue:(nullable dispatch_queue_t)queue
                          completionBlock:(AMAIdentifiersCompletionBlock)block
{
    [[self sharedImpl] requestStartupIdentifiersWithKeys:keys
                                         completionQueue:queue
                                         completionBlock:block
                                           notifyOnError:YES];
}

+ (NSString *)uuid
{
    return [AMAUUIDProvider sharedInstance].retrieveUUID;
}

+ (NSString *)deviceID
{
    NSString *deviceID = nil;
    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
    if (configuration.persistentConfigurationCreated) {
        NSString *currentDeviceID = configuration.persistent.deviceID;
        if (currentDeviceID.length != 0) {
            deviceID = currentDeviceID;
        }
    }
    return deviceID;
}

+ (NSString *)deviceIDHash
{
    NSString *deviceIDHash = nil;
    AMAMetricaConfiguration *configuration = [AMAMetricaConfiguration sharedInstance];
    if (configuration.persistentConfigurationCreated) {
        NSString *currentDeviceIDHash = configuration.persistent.deviceIDHash;
        if (currentDeviceIDHash.length != 0) {
            deviceIDHash = currentDeviceIDHash;
        }
    }
    return deviceIDHash;
}

+ (id<AMAAppMetricaPlugins>)pluginExtension
{
    return [self sharedPluginsImpl];
}

#pragma mark - Shared -

+ (AMAAppMetricaImpl *)sharedImpl
{
    static AMAAppMetricaImpl *appMetricaImpl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            appMetricaImpl = [[AMAAppMetricaImpl alloc] initWithHostStateProvider:[self sharedHostStateProvider]
                                                                         executor:[self sharedExecutor]];
            
            [[AMAMetricaConfiguration sharedInstance].inMemory markAppMetricaImplCreated];

            [appMetricaImpl startDispatcher];
        }
    });
    return appMetricaImpl;
}

+ (id<AMAHostStateProviding>)sharedHostStateProvider
{
    static id<AMAHostStateProviding> hostStateProvider = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            hostStateProvider = [[AMAHostStateProvider alloc] init];
        }
    });
    return hostStateProvider;
}

+ (id<AMAExecuting>)sharedExecutor
{
    static id<AMAExecuting> executor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            executor = [AMAAsyncExecutor new];
        }
    });
    return executor;
}

+ (AMAInternalEventsReporter *)sharedInternalEventsReporter
{
    static AMAInternalEventsReporter *reporter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            id<AMAExecuting> executor = [self sharedExecutor];
            id<AMAReporterProviding> reporterProvider =
                [[AMASharedReporterProvider alloc] initWithApiKey:kAMAMetricaLibraryApiKey];
            reporter = [[AMAInternalEventsReporter alloc] initWithExecutor:executor
                                                          reporterProvider:reporterProvider];
        }
    });
    return reporter;
}

+ (AMALogConfigurator *)sharedLogConfigurator
{
    static AMALogConfigurator *logConfigurator = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            logConfigurator = [AMALogConfigurator new];
        }
    });
    return logConfigurator;
}

+ (AMAAppMetricaPluginsImpl *)sharedPluginsImpl
{
    static AMAAppMetricaPluginsImpl *appMetricaPluginsImpl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            appMetricaPluginsImpl = [[AMAAppMetricaPluginsImpl alloc] init];
        }
    });
    return appMetricaPluginsImpl;
}

#pragma mark - Private & Testing Availability

+ (BOOL)isAppMetricaStartedWithLogging:(void (^)(NSError *))onFailure {
    if ([self isAppMetricaStarted] == NO) {
        [AMAErrorLogger logAppMetricaNotStartedErrorWithOnFailure:onFailure];
        return NO;
    }
    return YES;
}

+ (BOOL)isMetricaImplCreated
{
    @synchronized(self) {
        return [AMAMetricaConfiguration sharedInstance].inMemory.appMetricaImplCreated;
    }
}

+ (NSUInteger)dispatchPeriod
{
    AMAReporterConfiguration *configuration = [[AMAMetricaConfiguration sharedInstance] appConfiguration];
    return configuration.dispatchPeriod;
}

+ (NSUInteger)maxReportsCount
{
    AMAReporterConfiguration *configuration = [[AMAMetricaConfiguration sharedInstance] appConfiguration];
    return configuration.maxReportsCount;
}

+ (NSUInteger)sessionTimeout
{
    return [AMAMetricaConfiguration sharedInstance].appConfiguration.sessionTimeout;
}

+ (void)setBackgroundSessionTimeout:(NSUInteger)sessionTimeoutSeconds
{
    [AMAMetricaConfiguration sharedInstance].inMemory.backgroundSessionTimeout = sessionTimeoutSeconds;
}

+ (NSUInteger)backgroundSessionTimeout
{
    return [AMAMetricaConfiguration sharedInstance].inMemory.backgroundSessionTimeout;
}

+ (BOOL)isReportCrashesEnabled
{
    return [AMAMetricaConfiguration sharedInstance].inMemory.reportCrashesEnabled;
}

@end
