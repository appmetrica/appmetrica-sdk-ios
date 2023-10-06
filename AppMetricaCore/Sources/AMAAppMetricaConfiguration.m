
#import "AMACore.h"
#import "AMAAppMetricaConfiguration+Internal.h"
#import "AMAMetricaParametersScanner.h"
#import "AMAErrorLogger.h"
#import "AMAMetricaInMemoryConfiguration.h"

@interface AMAAppMetricaConfiguration ()

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, strong, nullable) NSNumber *locationTrackingState;
@property (nonatomic, strong, nullable) NSNumber *dataSendingEnabledState;

@end

@implementation AMAAppMetricaConfiguration

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super init];
    if (self != nil) {
        BOOL isKeyValid = [AMAIdentifierValidator isValidUUIDKey:apiKey];
        if (isKeyValid) {
            _apiKey = [apiKey copy];
            [self setDefaultValues];
        }
        else {
            [AMAErrorLogger logInvalidApiKeyError:apiKey];
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
    _accurateLocationTracking = NO;
    _location = nil;
    _logs = NO;
    _sessionTimeout = kAMASessionValidIntervalInSecondsDefault;
    _dispatchPeriod = kAMADefaultDispatchPeriodSeconds;
    _maxReportsCount = kAMAAutomaticReporterDefaultMaxReportsCount;
    _maxReportsInDatabaseCount = kAMAMaxReportsInDatabaseCount;
    _allowsBackgroundLocationUpdates = NO;
    _revenueAutoTrackingEnabled = kAMADefaultRevenueAutoTrackingEnabled;
    _appOpenTrackingEnabled = kAMADefaultAppOpenTrackingEnabled;
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

@end
