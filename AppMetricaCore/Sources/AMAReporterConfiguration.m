
#import "AMACore.h"
#import "AMAReporterConfiguration+Internal.h"
#import "AMAErrorLogger.h"
#import "AMAMetricaInMemoryConfiguration.h"

@interface AMAReporterConfiguration ()

@property (nonatomic, copy, readwrite) NSString *apiKey;
@property (nonatomic, assign, readwrite) NSUInteger dispatchPeriod;
@property (nonatomic, assign, readwrite) NSUInteger maxReportsCount;
@property (nonatomic, assign, readwrite) NSUInteger sessionTimeout;
@property (nonatomic, assign, readwrite) NSUInteger maxReportsInDatabaseCount;
@property (nonatomic, assign, readwrite) BOOL logs;
@property (nonatomic, copy, readwrite) NSString *userProfileID;

@property (nonatomic, strong, nullable, readwrite) NSNumber *dataSendingEnabledState;

@end

@implementation AMAReporterConfiguration

- (instancetype)initWithoutApiKey
{
    self = [super init];
    if (self != nil) {
        [self setDefaultValues];
    }
    return self;
}

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
    _dataSendingEnabledState = nil;
    _sessionTimeout = kAMASessionValidIntervalInSecondsDefault;
    _dispatchPeriod = kAMADefaultDispatchPeriodSeconds;
    _maxReportsCount = kAMAManualReporterDefaultMaxReportsCount;
    _maxReportsInDatabaseCount = kAMAMaxReportsInDatabaseCount;
    _logs = NO;
    _userProfileID = nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    AMAMutableReporterConfiguration *mutableConfiguration = [[AMAMutableReporterConfiguration alloc] initWithoutApiKey];
    if (mutableConfiguration != nil) {
        mutableConfiguration.apiKey = self.apiKey;
        mutableConfiguration.sessionTimeout = self.sessionTimeout;
        mutableConfiguration.dispatchPeriod = self.dispatchPeriod;
        mutableConfiguration.maxReportsCount = self.maxReportsCount;
        mutableConfiguration.maxReportsInDatabaseCount = self.maxReportsInDatabaseCount;
        mutableConfiguration.logs = self.logs;
        mutableConfiguration.userProfileID = self.userProfileID;
        mutableConfiguration.dataSendingEnabledState = self.dataSendingEnabledState;
    }
    return mutableConfiguration;
}

- (BOOL)dataSendingEnabled
{
    return self.dataSendingEnabledState != nil ? [self.dataSendingEnabledState boolValue] : YES;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ apiKey=%@, sessionTimeout=%@, dispatchPeriod=%@, "
                                       "maxReportsCount=%@, maxReportsInDatabaseCount=%@, "
                                       "logs=%@, userProfileID=%@, dataSendingEnabledState=%@",
                                       [super description], self.apiKey, @(self.sessionTimeout),
                                       @(self.dispatchPeriod), @(self.maxReportsCount),
                                       @(self.maxReportsInDatabaseCount), @(self.logs), self.userProfileID,
                                       self.dataSendingEnabledState];
}

#endif

@end

@implementation AMAMutableReporterConfiguration

@dynamic dataSendingEnabled;
@dynamic sessionTimeout;
@dynamic maxReportsInDatabaseCount;
@dynamic maxReportsCount;
@dynamic logs;
@dynamic userProfileID;
@dynamic dispatchPeriod;

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self = [super initWithApiKey:apiKey];
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    AMAReporterConfiguration *configuration = [[AMAReporterConfiguration alloc] initWithoutApiKey];
    if (configuration != nil) {
        configuration.apiKey = self.apiKey;
        configuration.sessionTimeout = self.sessionTimeout;
        configuration.dispatchPeriod = self.dispatchPeriod;
        configuration.maxReportsCount = self.maxReportsCount;
        configuration.maxReportsInDatabaseCount = self.maxReportsInDatabaseCount;
        configuration.logs = self.logs;
        configuration.userProfileID = self.userProfileID;
        configuration.dataSendingEnabledState = self.dataSendingEnabledState;
    }
    return configuration;
}

- (void)setDataSendingEnabled:(BOOL)enabled
{
    self.dataSendingEnabledState = @(enabled);
}

@end
