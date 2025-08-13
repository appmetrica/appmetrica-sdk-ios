
#import "AMACore.h"
#import "AMAAppMetrica+Internal.h"
#import "AMAAppMetricaConfigurationManager.h"
#import "AMAConfigForAnonymousActivationProvider.h"
#import "AMAMetricaConfiguration.h"
#import "AMADataSendingRestrictionController.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAMetricaPersistentConfiguration.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAMetricaParametersScanner.h"
#import "AMAErrorLogger.h"
#import "AMADispatchStrategiesContainer.h"
#import "AMADatabaseQueueProvider.h"
#import "AMADefaultAnonymousConfigProvider.h"
#import "AMAAppMetricaLibraryAdapterConfiguration+Internal.h"
#import "AMAPermissionResolving.h"
#import "AMALocationManager.h"
#import "AMALocationResolver.h"
#import "AMAAdProviderResolver.h"
#import "AMAActivationTypeResolver.h"

@interface AMAAppMetricaConfigurationManager ()

@property (nonatomic, strong) id<AMAAsyncExecuting, AMASyncExecuting> executor;
@property (nonatomic, strong) AMAConfigForAnonymousActivationProvider *anonymousConfigProvider;
@property (nonatomic, strong) AMAMetricaConfiguration *metricaConfiguration;
@property (nonatomic, strong) AMADataSendingRestrictionController *restrictionController;
@property (nonatomic, strong) AMADispatchStrategiesContainer *strategiesContainer;
@property (nonatomic, strong) AMAAppMetricaConfiguration *savedAnonimousConfiguration;
@property (nonatomic, strong) AMALocationManager *locationManager;
@property (nonatomic, strong) id<AMAPermissionResolvingInput> adProvidingResolver;
@property (nonatomic, strong) id<AMAPermissionResolvingInput> locationResolver;

@end

@implementation AMAAppMetricaConfigurationManager

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting,AMASyncExecuting>)executor
             strategiesContainer:(AMADispatchStrategiesContainer *)strategiesContainer
         firstActivationDetector:(AMAFirstActivationDetector *)firstActivationDetector
{
    AMAMetricaConfiguration *metricaConfiguration = [AMAMetricaConfiguration sharedInstance];
    AMAConfigForAnonymousActivationProvider *anonymousConfigProvider =
    [[AMAConfigForAnonymousActivationProvider alloc] initWithStorage:metricaConfiguration.persistent
                                                     defaultProvider:[[AMADefaultAnonymousConfigProvider alloc] init]
                                             firstActivationDetector:firstActivationDetector];
    return [self initWithExecutor:executor
              strategiesContainer:strategiesContainer
             metricaConfiguration:metricaConfiguration
            restrictionController:[AMADataSendingRestrictionController sharedInstance]
          anonymousConfigProvider:anonymousConfigProvider
                  locationManager:[AMALocationManager sharedManager]
                 locationResolver:[AMALocationResolver sharedInstance]
               adProviderResolver:[AMAAdProviderResolver sharedInstance]];
}

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting, AMASyncExecuting>)executor
             strategiesContainer:(AMADispatchStrategiesContainer *)strategiesContainer
            metricaConfiguration:(AMAMetricaConfiguration *)metricaConfiguration
           restrictionController:(AMADataSendingRestrictionController *)restrictionController
         anonymousConfigProvider:(AMAConfigForAnonymousActivationProvider *)anonymousConfigProvider
                 locationManager:(AMALocationManager *)locationManager
                locationResolver:(id<AMAPermissionResolvingInput>)locationResolver
              adProviderResolver:(id<AMAPermissionResolvingInput>)adProviderResolver
{
    self = [super init];
    if (self != nil) {
        _executor = executor;
        _strategiesContainer = strategiesContainer;
        _metricaConfiguration = metricaConfiguration;
        _restrictionController = restrictionController;
        _anonymousConfigProvider = anonymousConfigProvider;
        _locationManager = locationManager;
        _locationResolver = locationResolver;
        _adProvidingResolver = adProviderResolver;
    }
    return self;
}

- (void)updateMainConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    if (configuration == nil) {
        return;
    }
    [self importLogConfiguration:configuration];
    
    BOOL isAnonymous = [AMAActivationTypeResolver isAnonymousConfiguration:configuration];
    
    [self importLocationConfiguration:configuration isAnonymous:isAnonymous];
    [self importAdvertisingConfiguration:configuration isAnonymous:isAnonymous];
    [self importDataSendingEnabledConfiguration:configuration];
    self.metricaConfiguration.persistent.userStartupHosts = configuration.customHosts;
    
    [self setPreloadInfo:configuration.preloadInfo];
    
    [self importReporterConfiguration:configuration];
    [self importCustomVersionConfiguration:configuration];
    
    self.metricaConfiguration.persistent.appMetricaClientConfiguration = configuration;
    
    self.metricaConfiguration.persistent.recentMainApiKey = configuration.APIKey;
    
    [self handleConfigurationUpdate];
}

- (void)updateReporterConfiguration:(AMAReporterConfiguration *)configuration
{
    AMADataSendingRestriction restriction = AMADataSendingRestrictionUndefined;
    if (configuration.dataSendingEnabledState != nil) {
        restriction = [configuration.dataSendingEnabledState boolValue]
            ? AMADataSendingRestrictionAllowed
            : AMADataSendingRestrictionForbidden;
    }
    [self.restrictionController setReporterRestriction:restriction
                                             forApiKey:configuration.APIKey];
    
    [self.metricaConfiguration setConfiguration:configuration];
    
    [self handleConfigurationUpdate];
}

- (AMAAppMetricaConfiguration *)anonymousConfiguration
{
    return self.savedAnonimousConfiguration ?: [self.anonymousConfigProvider configuration];
}

- (void)updateAnonymousConfigurationWithLibraryAdapterConfiguration:(AMAAppMetricaLibraryAdapterConfiguration *)libraryAdapterConfiguration
{
    AMAAppMetricaConfiguration *configuration = [self.anonymousConfigProvider configuration];
    BOOL isAnonConfiguration = [AMAActivationTypeResolver isAnonymousConfiguration:configuration];
    
    if (isAnonConfiguration) {
        if (libraryAdapterConfiguration.locationTrackingEnabledValue != nil) {
            configuration.locationTracking = [libraryAdapterConfiguration.locationTrackingEnabledValue boolValue];
        }
        if (libraryAdapterConfiguration.advertisingIdentifierTrackingEnabledValue != nil) {
            configuration.advertisingIdentifierTrackingEnabled = [libraryAdapterConfiguration.advertisingIdentifierTrackingEnabledValue boolValue];
        }
    }
    
    self.savedAnonimousConfiguration = configuration;
}

#pragma mark - Handle configuration
- (void)importDataSendingEnabledConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMADataSendingRestriction restriction = AMADataSendingRestrictionUndefined;
    if (configuration.dataSendingEnabledState != nil) {
        restriction = [configuration.dataSendingEnabledState boolValue]
            ? AMADataSendingRestrictionAllowed
            : AMADataSendingRestrictionForbidden;
    }

    [self.restrictionController setMainApiKey:configuration.APIKey];
    [self.restrictionController setMainApiKeyRestriction:restriction];
}

- (void)importLocationConfiguration:(AMAAppMetricaConfiguration *)configuration isAnonymous:(BOOL)isAnonymous
{
    if (configuration.locationTrackingState != nil) {
        [self.locationResolver updateBoolValue:configuration.locationTrackingState isAnonymous:isAnonymous];
    }
    if (configuration.customLocation != nil) {
        self.locationManager.location = configuration.customLocation;
    }
    self.locationManager.accurateLocationEnabled = configuration.accurateLocationTracking;
}

- (void)importAdvertisingConfiguration:(AMAAppMetricaConfiguration *)configuration isAnonymous:(BOOL)isAnonymous
{
    if (configuration.advertisingIdentifierTrackingEnabledState != nil) {
        [self.adProvidingResolver updateBoolValue:configuration.advertisingIdentifierTrackingEnabledState isAnonymous:isAnonymous];
    }
}

- (void)importReporterConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    AMAMutableReporterConfiguration *appConfiguration =
        [self.metricaConfiguration.appConfiguration mutableCopy];
    appConfiguration.APIKey = configuration.APIKey;
    appConfiguration.sessionTimeout = configuration.sessionTimeout;
    appConfiguration.maxReportsCount = configuration.maxReportsCount;
    appConfiguration.maxReportsInDatabaseCount = configuration.maxReportsInDatabaseCount;
    appConfiguration.dispatchPeriod = configuration.dispatchPeriod;
    appConfiguration.logsEnabled = configuration.areLogsEnabled;
    appConfiguration.dataSendingEnabled = configuration.dataSendingEnabled;
    self.metricaConfiguration.appConfiguration = [appConfiguration copy];

    self.metricaConfiguration.inMemory.handleFirstActivationAsUpdate = configuration.handleFirstActivationAsUpdate;
    self.metricaConfiguration.inMemory.handleActivationAsSessionStart = configuration.handleActivationAsSessionStart;
    self.metricaConfiguration.inMemory.sessionsAutoTracking = configuration.sessionsAutoTracking;
}

- (void)importCustomVersionConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    if (configuration.appVersion.length != 0) {
        self.metricaConfiguration.inMemory.appVersion = configuration.appVersion;
    }
    if (configuration.appBuildNumber.length != 0) {
        uint32_t uintBuildNumber = 0;
        BOOL isNewValueValid = [AMAMetricaParametersScanner scanAppBuildNumber:&uintBuildNumber
                                                                      inString:configuration.appBuildNumber];
        if (isNewValueValid) {
            self.metricaConfiguration.inMemory.appBuildNumber = uintBuildNumber;
            self.metricaConfiguration.inMemory.appBuildNumberString = configuration.appBuildNumber;
        } else {
            [AMAErrorLogger logInvalidCustomAppBuildNumberError];
        }
    }
}

- (void)importLogConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    [AMAAppMetrica setLogs:configuration.areLogsEnabled];
    [self.executor execute:^{
        [AMADatabaseQueueProvider sharedInstance].logsEnabled = configuration.areLogsEnabled;
    }];
}

- (void)setPreloadInfo:(AMAAppMetricaPreloadInfo *)preloadInfo
{
    _preloadInfo = preloadInfo;

    if (preloadInfo != nil) {
        AMALogInfo(@"Set custom preload info %@", preloadInfo);
    }
}

// TODO: Observe configuration changes instead of calling this method on every configuration change
- (void)handleConfigurationUpdate
{
    [self execute:^{
        [self.strategiesContainer handleConfigurationUpdate];
    }];
}

- (void)execute:(dispatch_block_t)block
{
    [self.executor execute:block];
}

@end
