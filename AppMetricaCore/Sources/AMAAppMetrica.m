
#import <AppMetricaHostState/AppMetricaHostState.h>
#import <AppMetricaPlatform/AppMetricaPlatform.h>
#import "AMACore.h"
#if !TARGET_OS_TV
#endif
#import "AMAAppMetrica.h"
#import "AMAAdProvider.h"
#import "AMAAdRevenueInfo.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAAppMetricaConfiguration.h"
#import "AMAAppMetricaImpl.h"
#import "AMADataSendingRestrictionController.h"
#import "AMADatabaseQueueProvider.h"
#import "AMADeepLinkController.h"
#import "AMAErrorLogger.h"
#import "AMAInternalEventsReporter.h"
#import "AMALocationManager.h"
#import "AMAMetricaConfiguration.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaParametersScanner.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAReporterStoragesContainer.h"
#import "AMARevenueInfo.h"
#import "AMASharedReporterProvider.h"
#import "AMAStartupParametersConfiguration.h"
#import "AMAUserProfile.h"
#import "AMAAppMetricaConfigurationManager.h"
#import "AMAAdRevenueSourceContainer.h"
#import "AMAAdProviderResolver.h"
#import "AMALocationResolver.h"
@import AppMetricaIdentifiers;

NSString *const kAMAUUIDKey = @"appmetrica_uuid";
NSString *const kAMADeviceIDKey = @"appmetrica_deviceID";
NSString *const kAMADeviceIDHashKey = @"appmetrica_deviceIDHash";

NSString *const kAMAAttributionSourceAppsflyer = @"appsflyer";
NSString *const kAMAAttributionSourceAdjust = @"adjust";
NSString *const kAMAAttributionSourceKochava = @"kochava";
NSString *const kAMAAttributionSourceTenjin = @"tenjin";
NSString *const kAMAAttributionSourceAirbridge = @"airbridge";
NSString *const kAMAAttributionSourceSingular = @"singular";


@implementation AMAAppMetrica

#pragma mark - Shared Singletons -

+ (AMALocationManager *)sharedLocationManager
{
    return [AMALocationManager sharedManager];
}

+ (AMALocationResolver *)sharedLocationResolver
{
    return [AMALocationResolver sharedInstance];
}

+ (AMAAdProviderResolver *)sharedAdProviderResolver
{
    return [AMAAdProviderResolver sharedInstance];
}

+ (AMADataSendingRestrictionController *)sharedRestrictionController
{
    return [AMADataSendingRestrictionController sharedInstance];
}

+ (AMAAdRevenueSourceContainer *)sharedAdRevenueSourceContainer
{
    return [AMAAdRevenueSourceContainer sharedInstance];
}

#pragma mark - Core Extension -

+ (void)setAdProviderEnabled:(BOOL)newValue
{
    [self setAdvertisingIdentifierTrackingEnabled:newValue];
}

+ (BOOL)isAdvertisingIdentifierTrackingEnabled
{
    return [AMAAdProvider sharedInstance].isEnabled;
}

+ (void)setAdvertisingIdentifierTrackingEnabled:(BOOL)enabled
{
    [self sharedAdProviderResolver].userValue = @(enabled);
    AMALogInfo(@"Set track advertising enabled %i", enabled);
}


+ (void)setSessionExtras:(nullable NSData *)data forKey:(NSString *)key
{
    [[self sharedImpl] setSessionExtras:data forKey:key];
}

+ (void)clearSessionExtras
{
    [[self sharedImpl] clearSessionExtras];
}

+ (BOOL)isAPIKeyValid:(NSString *)apiKey
{
    return [AMAIdentifierValidator isValidUUIDKey:apiKey];
}

+ (BOOL)isActivated
{
    @synchronized(self) {
        return [self metricaConfiguration].inMemory.appMetricaStarted ||
               [self metricaConfiguration].inMemory.appMetricaStartedAnonymously;
    }
}

+ (BOOL)isAnonymousActivated
{
    @synchronized(self) {
        return [self metricaConfiguration].inMemory.appMetricaStartedAnonymously;
    }
}


+ (BOOL)isActivatedAsMain
{
    @synchronized(self) {
        return [self metricaConfiguration].inMemory.appMetricaStarted;
    }
}

+ (BOOL)isReporterCreatedForAPIKey:(NSString *)apiKey
{
    @synchronized(self) {
        return [self isMetricaImplCreated] && [[self sharedImpl] isReporterCreatedForAPIKey:apiKey];
    }
}

+ (BOOL)shouldReportToApiKey:(NSString *)apiKey
{
    return [[self sharedImpl] isAllowedToSendData:apiKey];
}

+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
           eventEnvironment:(NSDictionary *)eventEnvironment
             appEnvironment:(NSDictionary *)appEnvironment
                  onFailure:(nullable void (^)(NSError *error))onFailure
{
    [self reportEventWithType:eventType
                         name:name
                        value:value
             eventEnvironment:eventEnvironment
               appEnvironment:appEnvironment
                       extras:nil
                    onFailure:onFailure];
}

+ (void)reportEventWithType:(NSUInteger)eventType
                       name:(nullable NSString *)name
                      value:(nullable NSString *)value
           eventEnvironment:(nullable NSDictionary *)eventEnvironment
             appEnvironment:(nullable NSDictionary *)appEnvironment
                     extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                  onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportEventWithType:eventType
                                          name:name
                                         value:value
                              eventEnvironment:eventEnvironment
                                appEnvironment:appEnvironment
                                        extras:extras
                                     onFailure:onFailure];
    }
}

+ (void)reportBinaryEventWithType:(NSUInteger)eventType
                             data:(NSData *)data
                             name:(NSString *)name
                          gZipped:(BOOL)gZipped
                 eventEnvironment:(nullable NSDictionary *)eventEnvironment
                   appEnvironment:(nullable NSDictionary *)appEnvironment
                           extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                   bytesTruncated:(NSUInteger)bytesTruncated
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportBinaryEventWithType:eventType
                                                data:data
                                                name:name
                                             gZipped:gZipped
                                    eventEnvironment:eventEnvironment
                                      appEnvironment:appEnvironment
                                              extras:extras
                                      bytesTruncated:bytesTruncated
                                           onFailure:onFailure];
    }
}

+ (void)reportFileEventWithType:(NSUInteger)eventType
                           data:(NSData *)data
                       fileName:(NSString *)fileName
                           date:(nullable NSDate *)date
                        gZipped:(BOOL)gZipped
                      encrypted:(BOOL)encrypted
                      truncated:(BOOL)truncated
               eventEnvironment:(nullable NSDictionary *)eventEnvironment
                 appEnvironment:(nullable NSDictionary *)appEnvironment
                       appState:(nullable AMAApplicationState *)appState
                         extras:(nullable NSDictionary<NSString *, NSData *> *)extras
                      onFailure:(nullable void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportFileEventWithType:eventType
                                              data:data
                                          fileName:fileName
                                              date:date
                                           gZipped:gZipped
                                         encrypted:encrypted
                                         truncated:truncated
                                  eventEnvironment:eventEnvironment
                                    appEnvironment:appEnvironment
                                          appState:appState
                                            extras:extras
                                         onFailure:onFailure];
    }
}

+ (void)reportSystemEvent:(NSString *)name onFailure:(void (^)(NSError *))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportSystemEvent:name onFailure:onFailure];
    }
}

#pragma mark - Public API -

+ (void)activateWithConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    @synchronized (self) {
        if ([self isActivatedAsMain]) {
            [AMAErrorLogger logMetricaAlreadyStartedError];
            return;
        }
        if ([self isAPIKeyValid:configuration.APIKey] == NO) {
            [AMAErrorLogger logInvalidApiKeyError:configuration.APIKey];
            return;
        }
        if ([self isReporterCreatedForAPIKey:configuration.APIKey]) {
            [AMAErrorLogger logMetricaActivationWithAlreadyPresentedKeyError];
            return;
        }

        [[self sharedImpl] ensureModulesLoaded];
        [[self sharedImpl] activateWithConfiguration:configuration];
    }
}

+ (void)activate
{
    @synchronized (self) {
        if ([self isActivated]) {
            [AMAErrorLogger logMetricaAlreadyStartedError];
            return;
        }

        [[self sharedImpl] ensureModulesLoaded];
        [[self sharedImpl] scheduleAnonymousActivationIfNeeded];
    }
}

+ (void)setupLibraryAdapterConfiguration:(AMAAppMetricaLibraryAdapterConfiguration *)configuration
{
    @synchronized (self) {
        if ([self isActivatedAsMain] == NO) {
            [[self sharedImpl].configurationManager updateAnonymousConfigurationWithLibraryAdapterConfiguration:configuration];
        }
    }
    
}

+ (void)setLibraryAdapterAdvertisingIdentifierTracking:(BOOL)advertisingIdentifierTracking
{
    @synchronized (self) {
        [self sharedAdProviderResolver].anonymousValue = @(advertisingIdentifierTracking);
    }
}

+ (void)setLibraryAdapterLocationTracking:(BOOL)locationTracking
{
    @synchronized (self) {
        [self sharedLocationResolver].anonymousValue = @(locationTracking);
    }
}

+ (void)reportEvent:(NSString *)name onFailure:(void (^)(NSError *error))onFailure
{
    [[self class] reportEvent:name parameters:nil onFailure:onFailure];
}

+ (void)reportEvent:(NSString *)name
         parameters:(NSDictionary *)params
          onFailure:(void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportEvent:[name copy] parameters:[params copy] onFailure:onFailure];
    }
}

+ (void)reportLibraryAdapterAdRevenueRelatedEvent:(NSString *)name
                                       parameters:(NSDictionary *)params
                                        onFailure:(void (^)(NSError *error))onFailure
{
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportLibraryAdapterAdRevenueRelatedEvent:[name copy] parameters:[params copy] onFailure:onFailure];
    }
}

+ (void)reportUserProfile:(AMAUserProfile *)userProfile onFailure:(nullable void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportUserProfile:[userProfile copy] onFailure:onFailure];
    }
}

+ (void)reportRevenue:(AMARevenueInfo *)revenueInfo onFailure:(nullable void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportRevenue:revenueInfo onFailure:onFailure];
    }
}

+ (void)reportECommerce:(AMAECommerce *)eCommerce onFailure:(void (^)(NSError *))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportECommerce:eCommerce onFailure:onFailure];
    }
}

+ (void)reportExternalAttribution:(NSDictionary *)attribution
                           source:(AMAAttributionSource)source
                        onFailure:(nullable void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportExternalAttribution:attribution source:source onFailure:onFailure];
    }
}

+ (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenue onFailure:(void (^)(NSError *error))onFailure
{
    [self reportAdRevenue:adRevenue isAutocollected:NO onFailure:onFailure];
}

+ (void)reportAdRevenue:(AMAAdRevenueInfo *)adRevenue
        isAutocollected:(BOOL)isAutocollected
              onFailure:(nullable void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] reportAdRevenue:adRevenue isAutocollected:isAutocollected onFailure:onFailure];
    }
}


#if !TARGET_OS_TV
+ (void)setupWebViewReporting:(id<AMAJSControlling>)controller
                    onFailure:(nullable void (^)(NSError *error))onFailure
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:onFailure]) {
        [[self sharedImpl] setupWebViewReporting:controller];
    }
}
#endif

+ (void)setUserProfileID:(NSString *)userProfileID
{
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] setUserProfileID:[userProfileID copy]];
}

+ (NSString *)userProfileID
{
    return [self sharedImpl].userProfileID;
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
    [[self sharedRestrictionController] setMainApiKeyRestriction:restriction];
}

#if TARGET_OS_IOS
+ (void)sendMockVisit:(CLVisit *)visit
{
    [[self sharedLocationManager] sendMockVisit:visit];
}
# endif

+ (void)setCustomLocation:(CLLocation *)location
{
    [[self sharedLocationManager] setLocation:location];
    AMALogInfo(@"Set location %@", location);
}

+ (CLLocation *)customLocation
{
    return [self sharedLocationManager].location;
}

+ (void)setLocationTrackingEnabled:(BOOL)enabled
{
    [self sharedLocationResolver].userValue = @(enabled);
    AMALogInfo(@"Set track location enabled %i", enabled);
}

+ (BOOL)isLocationTrackingEnabled
{
    return [self sharedLocationManager].trackLocationEnabled;
}

+ (NSString *)libraryVersion
{
    return [AMAPlatformDescription SDKVersionName];
}

+ (void)trackOpeningURL:(NSURL *)URL
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isActivated] == NO) {
        AMALogWarn(@"Metrica is not started");
        return;
    }
    [[self sharedImpl] reportUrl:URL ofType:kAMADLControllerUrlTypeOpen isAuto:NO];
}

+ (void)setErrorEnvironmentValue:(NSString *)value forKey:(NSString *)key
{
    [[self sharedImpl] ensureModulesLoaded];
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
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] setAppEnvironmentValue:value forKey:key];
}

+ (void)clearAppEnvironment
{
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] clearAppEnvironment];
}

+ (void)sendEventsBuffer
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    [[self sharedImpl] sendEventsBuffer];
}

+ (void)pauseSession
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    if ([self metricaConfiguration].inMemory.sessionsAutoTracking) {
        [AMAErrorLogger logMetricaActivationWithAutomaticSessionsTracking];
        return;
    }
    [[self sharedImpl] pauseSession];
}

+ (void)resumeSession
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAppMetricaStartedWithLogging:nil] == NO) { return; }
    if ([self metricaConfiguration].inMemory.sessionsAutoTracking) {
        [AMAErrorLogger logMetricaActivationWithAutomaticSessionsTracking];
        return;
    }
    [[self sharedImpl] resumeSession];
}

+ (void)setAccurateLocationTrackingEnabled:(BOOL)enabled
{
    [self sharedLocationManager].accurateLocationEnabled = enabled;
}

+ (BOOL)isAccurateLocationTrackingEnabled
{
    return [self sharedLocationManager].accurateLocationEnabled;
}

+ (void)setAllowsBackgroundLocationUpdates:(BOOL)allowsBackgroundLocationUpdates
{
    [self sharedLocationManager].allowsBackgroundLocationUpdates = allowsBackgroundLocationUpdates;
}

+ (BOOL)allowsBackgroundLocationUpdates
{
    return [self sharedLocationManager].allowsBackgroundLocationUpdates;
}

+ (void)activateReporterWithConfiguration:(AMAReporterConfiguration *)configuration
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAPIKeyValid:configuration.APIKey] == NO) {
        [AMAErrorLogger logInvalidApiKeyError:configuration.APIKey];
        return;
    }

    @synchronized (self) {
        if ([self isReporterCreatedForAPIKey:configuration.APIKey]) {
            [AMAErrorLogger logMetricaActivationWithAlreadyPresentedKeyError];
        }
        else {
            [[self sharedImpl] activateReporterWithConfiguration:configuration];
        }
    }
}

+ (id<AMAAppMetricaReporting>)reporterForAPIKey:(NSString *)APIKey
{
    return [self extendedReporterForApiKey:APIKey];
}

+ (id<AMAAppMetricaExtendedReporting>)extendedReporterForApiKey:(NSString *)apiKey
{
    [[self sharedImpl] ensureModulesLoaded];
    if ([self isAPIKeyValid:apiKey] == NO) {
        [AMAErrorLogger logInvalidApiKeyError:apiKey];
        return nil;
    }

    @synchronized (self) {
        if ([self isReporterCreatedForAPIKey:apiKey] == NO) {
            [[self sharedRestrictionController] setReporterRestriction:AMADataSendingRestrictionUndefined
                                                             forApiKey:apiKey];
        }
        AMAReporterConfiguration *configuration = [[AMAReporterConfiguration alloc] initWithAPIKey:apiKey];
        id<AMAAppMetricaExtendedReporting> reporter = [[self sharedImpl] manualReporterForConfiguration:configuration];
        return reporter;
    }
}

+ (void)requestStartupIdentifiersWithCompletionQueue:(nullable dispatch_queue_t)queue
                                     completionBlock:(AMAIdentifiersCompletionBlock)block
{
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] requestStartupIdentifiersWithCompletionQueue:queue
                                                    completionBlock:block
                                                      notifyOnError:YES];
}

+ (void)requestStartupIdentifiersWithKeys:(NSArray<NSString *> *)keys
                          completionQueue:(nullable dispatch_queue_t)queue
                          completionBlock:(AMAIdentifiersCompletionBlock)block
{
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] requestStartupIdentifiersWithKeys:keys
                                         completionQueue:queue
                                         completionBlock:block
                                           notifyOnError:YES];
}

+ (NSString *)UUID
{
    [[self metricaConfiguration] ensureMigrated];
    return [self metricaConfiguration].identifierProvider.appMetricaUUID;
}

+ (NSString *)deviceID
{
    NSString *deviceID = nil;
    AMAMetricaConfiguration *configuration = [self metricaConfiguration];
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
    AMAMetricaConfiguration *configuration = [self metricaConfiguration];
    if (configuration.persistentConfigurationCreated) {
        NSString *currentDeviceIDHash = configuration.persistent.deviceIDHash;
        if (currentDeviceIDHash.length != 0) {
            deviceIDHash = currentDeviceIDHash;
        }
    }
    return deviceIDHash;
}

#pragma mark - Shared -

+ (AMAAppMetricaImpl *)sharedImpl
{
    static AMAAppMetricaImpl *appMetricaImpl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            appMetricaImpl = [[AMAAppMetricaImpl alloc] initWithHostStateProvider:self.sharedHostStateProvider
                                                                         executor:self.sharedExecutor];

            [[self metricaConfiguration].inMemory markAppMetricaImplCreated];

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

+ (id<AMAAsyncExecuting, AMASyncExecuting>)sharedExecutor
{
    static id<AMAAsyncExecuting, AMASyncExecuting> executor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @autoreleasepool {
            executor = [AMAExecutor new];
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
            id<AMAAsyncExecuting> executor = [self sharedExecutor];
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
            [logConfigurator setupLogWithChannel:AMA_LOG_CHANNEL];
            [logConfigurator setChannel:AMA_LOG_CHANNEL enabled:NO];
        }
    });
    return logConfigurator;
}

+ (void)subscribeForAutocollectedDataForApiKey:(NSString *)apiKey
{
    [[self sharedImpl] ensureModulesLoaded];
    [[self sharedImpl] addAutocollectedData:apiKey];
}

#pragma mark - Private & Testing Availability

+ (AMAMetricaConfiguration *)metricaConfiguration
{
    return [AMAMetricaConfiguration sharedInstance];
}


+ (BOOL)isAppMetricaStartedWithLogging:(void (^)(NSError *))onFailure {
    if ([self isActivated] == NO) {
        [AMAErrorLogger logAppMetricaNotActivatedErrorWithOnFailure:onFailure];
        return NO;
    }
    return YES;
}

+ (BOOL)isMetricaImplCreated
{
    @synchronized(self) {
        return [self metricaConfiguration].inMemory.appMetricaImplCreated;
    }
}

+ (NSUInteger)dispatchPeriod
{
    AMAReporterConfiguration *configuration = [[self metricaConfiguration] appConfiguration];
    return configuration.dispatchPeriod;
}

+ (NSUInteger)maxReportsCount
{
    AMAReporterConfiguration *configuration = [[self metricaConfiguration] appConfiguration];
    return configuration.maxReportsCount;
}

+ (NSUInteger)sessionTimeout
{
    return [self metricaConfiguration].appConfiguration.sessionTimeout;
}

+ (void)setBackgroundSessionTimeout:(NSUInteger)sessionTimeoutSeconds
{
    [self metricaConfiguration].inMemory.backgroundSessionTimeout = sessionTimeoutSeconds;
}

+ (NSUInteger)backgroundSessionTimeout
{
    return [self metricaConfiguration].inMemory.backgroundSessionTimeout;
}

+ (void)registerAdRevenueNativeSource:(NSString *)source
{
    [[self sharedAdRevenueSourceContainer] addNativeSupportedSource:source];
}

#pragma mark - Deprecated module registration

// These methods are no-ops kept for binary compatibility.
// Use AMAModuleContext in AMAModuleEntryPoint.initModuleWithContext: instead.

+ (void)addActivationDelegate:(Class<AMAModuleActivationDelegate>)delegate
{
    [[self sharedImpl] addActivationDelegate:delegate];
}

+ (void)registerExternalService:(AMAServiceConfiguration *)configuration
{
    [[self sharedImpl] registerExternalService:configuration];
}

@end
