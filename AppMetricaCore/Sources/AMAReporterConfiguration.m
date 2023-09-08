
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

@property (nonatomic, strong, nullable, readwrite) NSNumber *statisticsSendingState;

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
    _statisticsSendingState = nil;
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
        mutableConfiguration.statisticsSendingState = self.statisticsSendingState;
    }
    return mutableConfiguration;
}

- (BOOL)statisticsSending
{
    return self.statisticsSendingState != nil ? [self.statisticsSendingState boolValue] : YES;
}

#if AMA_ALLOW_DESCRIPTIONS

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ apiKey=%@, sessionTimeout=%@, dispatchPeriod=%@, "
                                       "maxReportsCount=%@, maxReportsInDatabaseCount=%@, "
                                       "logs=%@, userProfileID=%@, statisticsSendingState=%@",
                                       [super description], self.apiKey, @(self.sessionTimeout),
                                       @(self.dispatchPeriod), @(self.maxReportsCount),
                                       @(self.maxReportsInDatabaseCount), @(self.logs), self.userProfileID,
                                       self.statisticsSendingState];
}

#endif

@end

@implementation AMAMutableReporterConfiguration

@dynamic statisticsSending;
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
        configuration.statisticsSendingState = self.statisticsSendingState;
    }
    return configuration;
}

- (void)setStatisticsSending:(BOOL)enabled
{
    self.statisticsSendingState = @(enabled);
}

@end
