
#import "AMACore.h"
#import "AMAMetricaInMemoryConfiguration.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

static NSUInteger const kAMADefaultBatchSize = 10000;
static double const kAMATrimEventsPercent = 0.1;
static NSUInteger const kAMAMaxProtobufMessageSize = 1024 * 245;
static NSUInteger const kAMAMaxSessionDurationSeconds = 24 * 60 * 60;
static NSUInteger const kAMABackgroundSessionTimeoutSeconds = 60 * 60;
static NSUInteger const kAMADefaultUpdateSessionStampTimerInterval = 10;

NSString *const kAMADefaultStartupHost = @"https://startup.mobile.yandex.net";

NSUInteger const kAMADefaultDispatchPeriodSeconds = 90;
NSUInteger const kAMAAutomaticReporterDefaultMaxReportsCount = 7;
NSUInteger const kAMAManualReporterDefaultMaxReportsCount = 1;
NSUInteger const kAMASessionValidIntervalInSecondsDefault = 10;
NSUInteger const kAMAMinSessionTimeoutInSeconds = 10;
NSUInteger const kAMAMaxReportsInDatabaseCount = 1000;
NSUInteger const kAMAMinValueOfMaxReportsInDatabaseCount = 100;
NSUInteger const kAMAMaxValueOfMaxReportsInDatabaseCount = 10000;
BOOL const kAMADefaultRevenueAutoTrackingEnabled = YES;
BOOL const kAMADefaultAppOpenTrackingEnabled = YES;

NSString *const kAMAMetricaLibraryApiKey = @"20799a27-fa80-4b36-b2db-0f8141f24180";

@interface AMAMetricaInMemoryConfiguration ()

@property (atomic, assign, readwrite) BOOL metricaStarted;
@property (atomic, assign, readwrite) BOOL metricaImplCreated;

@end

@implementation AMAMetricaInMemoryConfiguration

@synthesize appBuildUID = _appBuildUID;

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _batchSize = kAMADefaultBatchSize;
        _trimEventsPercent = kAMATrimEventsPercent;
        _maxProtobufMsgSize = kAMAMaxProtobufMessageSize;
        _sessionMaxDuration = kAMAMaxSessionDurationSeconds;
        _backgroundSessionTimeout = kAMABackgroundSessionTimeoutSeconds;
        _reportCrashesEnabled = YES;
        _appVersion = [AMAPlatformDescription appVersion];
        _appBuildNumber = (uint32_t)[[AMAPlatformDescription appBuildNumber] intValue];
        _updateSessionStampInterval = kAMADefaultUpdateSessionStampTimerInterval;
        _sessionsAutoTracking = YES;
    }
    return self;
}

- (AMABuildUID *)appBuildUID
{
    if (_appBuildUID == nil) {
        @synchronized (self) {
            if (_appBuildUID == nil) {
                _appBuildUID = [AMABuildUID buildUID];
            }
        }
    }
    return _appBuildUID;
}

- (void)markMetricaStarted
{
    self.metricaStarted = YES;
}

- (void)markMetricaImplCreated
{
    self.metricaImplCreated = YES;
}

@end
