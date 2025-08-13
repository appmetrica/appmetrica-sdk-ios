
#import "AMACore.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAMetricaParametersScanner.h"
#import "AMAErrorLogger.h"
#import "AMAMetricaInMemoryConfiguration.h"

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

@end
