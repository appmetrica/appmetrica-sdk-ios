
#import "AMAAppMetricaCrashesConfiguration.h"

static BOOL AMAIsValidPreActivationAppBuildNumber(NSString *appBuildNumber)
{
    if (appBuildNumber == nil) {
        return NO;
    }

    NSScanner *scanner = [NSScanner scannerWithString:appBuildNumber];
    unsigned long long value = 0;
    return [scanner scanUnsignedLongLong:&value] && scanner.atEnd && value <= UINT32_MAX;
}

@implementation AMAAppMetricaCrashesConfiguration

- (instancetype)init 
{
    self = [super init];
    if (self != nil) {
        _preActivationAppVersion = nil;
        _preActivationAppBuildNumber = nil;
        _autoCrashTracking = YES;
        _probablyUnhandledCrashReporting = NO;
        _ignoredCrashSignals = nil;
        _applicationNotRespondingDetection = NO;
        _applicationNotRespondingWatchdogInterval = 4.0;
        _applicationNotRespondingPingInterval = 0.1;
        _crashErrorEnvironmentCallback = NULL;
    }
    return self;
}

- (BOOL)isEqual:(id)object 
{
    if ([object isMemberOfClass:self.class] == NO) {
        return NO;
    }
    
    AMAAppMetricaCrashesConfiguration *config = (AMAAppMetricaCrashesConfiguration *)object;
    
    return ([self bothValuesAreNilOrValue:self.preActivationAppVersion
                           isEqualToValue:config.preActivationAppVersion] &&
            [self bothValuesAreNilOrValue:self.preActivationAppBuildNumber
                           isEqualToValue:config.preActivationAppBuildNumber] &&
            self.autoCrashTracking == config.autoCrashTracking &&
            self.probablyUnhandledCrashReporting == config.probablyUnhandledCrashReporting &&
            [self bothValuesAreNilOrValue:self.ignoredCrashSignals isEqualToValue:config.ignoredCrashSignals] &&
            self.applicationNotRespondingDetection == config.applicationNotRespondingDetection &&
            self.applicationNotRespondingWatchdogInterval == config.applicationNotRespondingWatchdogInterval &&
            self.applicationNotRespondingPingInterval == config.applicationNotRespondingPingInterval &&
            self.crashErrorEnvironmentCallback == config.crashErrorEnvironmentCallback);
}

- (NSUInteger)hash
{
    NSUInteger prime = 31;
    NSUInteger result = 1;
    
    result = prime * result + [self.class hash];
    result = prime * result + [self.preActivationAppVersion hash];
    result = prime * result + [self.preActivationAppBuildNumber hash];
    result = prime * result + (self.autoCrashTracking ? 1 : 0);
    result = prime * result + (self.probablyUnhandledCrashReporting ? 1 : 0);
    result = prime * result + [self.ignoredCrashSignals hash];
    result = prime * result + (self.applicationNotRespondingDetection ? 1 : 0);
    result = prime * result + (NSUInteger)(self.applicationNotRespondingWatchdogInterval * 1000);
    result = prime * result + (NSUInteger)(self.applicationNotRespondingPingInterval * 1000);
    result = prime * result + (NSUInteger)(uintptr_t)self.crashErrorEnvironmentCallback;
    
    return result;
}

- (BOOL)bothValuesAreNilOrValue:(id)value isEqualToValue:(id)anotherValue
{
    return (value == nil && anotherValue == nil) || [value isEqual:anotherValue];
}

- (void)setPreActivationAppVersion:(NSString *)appVersion
{
    if (appVersion.length > 0) {
        _preActivationAppVersion = [appVersion copy];
    }
}

- (void)setPreActivationAppBuildNumber:(NSString *)appBuildNumber
{
    if (AMAIsValidPreActivationAppBuildNumber(appBuildNumber)) {
        _preActivationAppBuildNumber = [appBuildNumber copy];
    }
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    AMAAppMetricaCrashesConfiguration *copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        copy->_preActivationAppVersion = [_preActivationAppVersion copyWithZone:zone];
        copy->_preActivationAppBuildNumber = [_preActivationAppBuildNumber copyWithZone:zone];
        copy->_autoCrashTracking = _autoCrashTracking;
        copy->_probablyUnhandledCrashReporting = _probablyUnhandledCrashReporting;
        copy->_ignoredCrashSignals = [_ignoredCrashSignals copyWithZone:zone];
        copy->_applicationNotRespondingDetection = _applicationNotRespondingDetection;
        copy->_applicationNotRespondingWatchdogInterval = _applicationNotRespondingWatchdogInterval;
        copy->_applicationNotRespondingPingInterval = _applicationNotRespondingPingInterval;
        copy->_crashErrorEnvironmentCallback = _crashErrorEnvironmentCallback;
    }
    return copy;
}

@end
