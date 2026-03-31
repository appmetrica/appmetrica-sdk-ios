
#import "AMACore.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAMetricaParametersScanner.h"
#import "AMAErrorLogger.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import "AMAAppMetricaPreloadInfo+AMAInternal.h"
#import <CoreLocation/CoreLocation.h>

@interface AMAAppMetricaConfiguration ()

@property (nonatomic, copy, readwrite) NSString *APIKey;
@property (nonatomic, copy, nullable, readwrite) NSNumber *locationTrackingState;
@property (nonatomic, copy, nullable, readwrite) NSNumber *dataSendingEnabledState;
@property (nonatomic, copy, nullable, readwrite) NSNumber *advertisingIdentifierTrackingEnabledState;

@end

@implementation AMAAppMetricaConfiguration

- (instancetype)initWithAPIKey:(NSString *)APIKey
{
    self = [super init];
    if (self != nil) {
        BOOL isKeyValid = [AMAIdentifierValidator isValidUUIDKey:APIKey];
        if (isKeyValid) {
            _APIKey = [APIKey copy];
            [self setDefaultValues];
        }
        else {
            [AMAErrorLogger logInvalidApiKeyError:APIKey];
            self = nil;
        }
    }
    return self;
}

- (void)setDefaultValues
{
    _handleFirstActivationAsUpdate = NO;
    _handleActivationAsSessionStart = NO;
    _sessionsAutoTracking = YES;
    _locationTrackingState = nil;
    _dataSendingEnabledState = nil;
    _advertisingIdentifierTrackingEnabledState = nil;
    _accurateLocationTracking = NO;
    _customLocation = nil;
    _logsEnabled = NO;
    _sessionTimeout = kAMASessionValidIntervalInSecondsDefault;
    _dispatchPeriod = kAMADefaultDispatchPeriodSeconds;
    _maxReportsCount = kAMAAutomaticReporterDefaultMaxReportsCount;
    _maxReportsInDatabaseCount = kAMAMaxReportsInDatabaseCount;
    _allowsBackgroundLocationUpdates = NO;
    _revenueAutoTrackingEnabled = kAMADefaultRevenueAutoTrackingEnabled;
    _appOpenTrackingEnabled = kAMADefaultAppOpenTrackingEnabled;
    _appEnvironment = nil;
}

#pragma mark - Properties

- (void)setAppVersion:(NSString *)appVersion
{
    BOOL isNewValueValid = appVersion.length != 0;
    if (isNewValueValid == NO) {
        [AMAErrorLogger logInvalidCustomAppVersionError];
    }
    else {
        _appVersion = [appVersion copy];
    }
}

- (void)setAppBuildNumber:(NSString *)appBuildNumber
{
    uint32_t integerValue;
    BOOL isNewValueValid = [AMAMetricaParametersScanner scanAppBuildNumber:&integerValue
                                                                  inString:appBuildNumber];

    if (isNewValueValid == NO) {
        [AMAErrorLogger logInvalidCustomAppBuildNumberError];
    }
    else {
        _appBuildNumber = [appBuildNumber copy];
    }
}

- (void)setLocationTracking:(BOOL)enabled
{
    self.locationTrackingState = @(enabled);
}

- (BOOL)locationTracking
{
    return self.locationTrackingState != nil ? [self.locationTrackingState boolValue] : YES;
}

- (void)setDataSendingEnabled:(BOOL)enabled
{
    self.dataSendingEnabledState = @(enabled);
}

- (BOOL)dataSendingEnabled
{
    return self.dataSendingEnabledState != nil ? [self.dataSendingEnabledState boolValue] : YES;
}

- (BOOL)advertisingIdentifierTrackingEnabled
{
    return self.advertisingIdentifierTrackingEnabledState != nil ? [self.advertisingIdentifierTrackingEnabledState boolValue] : YES;
}

- (void)setAdvertisingIdentifierTrackingEnabled:(BOOL)advertisingIdentifierTrackingEnabled
{
    self.advertisingIdentifierTrackingEnabledState = @(advertisingIdentifierTrackingEnabled);
}

- (id)copyWithZone:(NSZone *)zone
{
    AMAAppMetricaConfiguration *cfg = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:self.APIKey];
    
    cfg.handleFirstActivationAsUpdate = self.handleFirstActivationAsUpdate;
    cfg.handleActivationAsSessionStart = self.handleActivationAsSessionStart;
    cfg.sessionsAutoTracking = self.sessionsAutoTracking;
    cfg.locationTrackingState = [self.locationTrackingState copy];
    cfg.dataSendingEnabledState = [self.dataSendingEnabledState copy];
    cfg.advertisingIdentifierTrackingEnabledState = [self.advertisingIdentifierTrackingEnabledState copy];
    cfg.maxReportsInDatabaseCount = self.maxReportsInDatabaseCount;
    cfg.allowsBackgroundLocationUpdates = self.allowsBackgroundLocationUpdates;
    cfg.accurateLocationTracking = self.accurateLocationTracking;
    cfg.dispatchPeriod = self.dispatchPeriod;
    cfg.customLocation = self.customLocation;
    cfg.sessionTimeout = self.sessionTimeout;
    cfg.appVersion = self.appVersion;
    cfg.logsEnabled = self.logsEnabled;
    cfg.preloadInfo = [self.preloadInfo copy];
    cfg.revenueAutoTrackingEnabled = self.revenueAutoTrackingEnabled;
    cfg.appOpenTrackingEnabled = self.appOpenTrackingEnabled;
    cfg.userProfileID = self.userProfileID;
    cfg.maxReportsCount = self.maxReportsCount;
    cfg.appBuildNumber = self.appBuildNumber;
    cfg.customHosts = self.customHosts;
    cfg.appEnvironment = self.appEnvironment;
    
    return cfg;
}

- (BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    }
    if ([object isKindOfClass:[AMAAppMetricaConfiguration class]] == NO) {
        return NO;
    }
    return [self isEqualToConfiguration:(AMAAppMetricaConfiguration *)object];
}

- (BOOL)isEqualToConfiguration:(nonnull AMAAppMetricaConfiguration *)configuration
{    
    if (self == configuration) {
        return YES;
    }
    
    if ([self.APIKey isEqualToString:configuration.APIKey] == NO) {
        return NO;
    }
    
    if (self.handleFirstActivationAsUpdate != configuration.handleFirstActivationAsUpdate) {
        return NO;
    }
    
    if (self.handleActivationAsSessionStart != configuration.handleActivationAsSessionStart) {
        return NO;
    }
    
    if (self.sessionsAutoTracking != configuration.sessionsAutoTracking) {
        return NO;
    }
    
    if (self.accurateLocationTracking != configuration.accurateLocationTracking) {
        return NO;
    }
    
    if (self.logsEnabled != configuration.logsEnabled) {
        return NO;
    }
    
    if (self.allowsBackgroundLocationUpdates != configuration.allowsBackgroundLocationUpdates) {
        return NO;
    }
    
    if (self.revenueAutoTrackingEnabled != configuration.revenueAutoTrackingEnabled) {
        return NO;
    }
    
    if (self.appOpenTrackingEnabled != configuration.appOpenTrackingEnabled) {
        return NO;
    }
    
    if (self.locationTrackingState != configuration.locationTrackingState &&
        ![self.locationTrackingState isEqualToNumber:configuration.locationTrackingState]) {
        return NO;
    }
    
    if (self.dataSendingEnabledState != configuration.dataSendingEnabledState &&
        ![self.dataSendingEnabledState isEqualToNumber:configuration.dataSendingEnabledState]) {
        return NO;
    }
    
    if (self.advertisingIdentifierTrackingEnabledState != configuration.advertisingIdentifierTrackingEnabledState &&
        ![self.advertisingIdentifierTrackingEnabledState isEqualToNumber:configuration.advertisingIdentifierTrackingEnabledState]) {
        return NO;
    }
    
    if (self.sessionTimeout != configuration.sessionTimeout) {
        return NO;
    }
    
    if (self.dispatchPeriod != configuration.dispatchPeriod) {
        return NO;
    }
    
    if (self.maxReportsCount != configuration.maxReportsCount) {
        return NO;
    }
    
    if (self.maxReportsInDatabaseCount != configuration.maxReportsInDatabaseCount) {
        return NO;
    }
    
    if (self.appVersion != configuration.appVersion &&
        ![self.appVersion isEqualToString:configuration.appVersion]) {
        return NO;
    }
    
    if (self.appBuildNumber != configuration.appBuildNumber &&
        ![self.appBuildNumber isEqualToString:configuration.appBuildNumber]) {
        return NO;
    }
    
    if (self.userProfileID != configuration.userProfileID &&
        ![self.userProfileID isEqualToString:configuration.userProfileID]) {
        return NO;
    }
    
    if (self.customLocation != configuration.customLocation &&
        ![self.customLocation isEqual:configuration.customLocation]) {
        return NO;
    }

    if (self.preloadInfo != configuration.preloadInfo &&
        ![self.preloadInfo isEqualToPreloadInfo:configuration.preloadInfo]) {
        return NO;
    }
    
    if (self.customHosts != configuration.customHosts &&
        ![self.customHosts isEqualToArray:configuration.customHosts]) {
        return NO;
    }
    
    if (self.appEnvironment != configuration.appEnvironment &&
        ![self.appEnvironment isEqualToDictionary:configuration.appEnvironment]) {
        return NO;
    }
    
    return YES;
}

@end
