#import "AMAStartupParametersConfigurationMock.h"

@implementation AMAStartupParametersConfigurationMock

@synthesize retryPolicyMaxIntervalSeconds = _retryPolicyMaxIntervalSeconds;
@synthesize retryPolicyExponentialMultiplier = _retryPolicyExponentialMultiplier;
@synthesize serverTimeOffset = _serverTimeOffset;
@synthesize initialCountry = _initialCountry;
@synthesize permissionsString = _permissionsString;
@synthesize startupHosts = _startupHosts;
@synthesize startupUpdateInterval = _startupUpdateInterval;
@synthesize reportHosts = _reportHosts;
@synthesize redirectHost = _redirectHost;
@synthesize SDKsCustomHosts = _SDKsCustomHosts;
@synthesize permissionsCollectingEnabled = _permissionsCollectingEnabled;
@synthesize permissionsCollectingList = _permissionsCollectingList;
@synthesize permissionsCollectingForceSendInterval = _permissionsCollectingForceSendInterval;
@synthesize statSendingDisabledReportingInterval = _statSendingDisabledReportingInterval;
@synthesize extensionsCollectingEnabled = _extensionsCollectingEnabled;
@synthesize extensionsCollectingInterval = _extensionsCollectingInterval;
@synthesize extensionsCollectingLaunchDelay = _extensionsCollectingLaunchDelay;
@synthesize locationCollectingEnabled = _locationCollectingEnabled;
@synthesize locationVisitsCollectingEnabled = _locationVisitsCollectingEnabled;
@synthesize locationHosts = _locationHosts;
@synthesize locationMinUpdateInterval = _locationMinUpdateInterval;
@synthesize locationMinUpdateDistance = _locationMinUpdateDistance;
@synthesize locationRecordsCountToForceFlush = _locationRecordsCountToForceFlush;
@synthesize locationMaxRecordsCountInBatch = _locationMaxRecordsCountInBatch;
@synthesize locationMaxAgeToForceFlush = _locationMaxAgeToForceFlush;
@synthesize locationMaxRecordsToStoreLocally = _locationMaxRecordsToStoreLocally;
@synthesize locationDefaultDesiredAccuracy = _locationDefaultDesiredAccuracy;
@synthesize locationDefaultDistanceFilter = _locationDefaultDistanceFilter;
@synthesize locationAccurateDesiredAccuracy = _locationAccurateDesiredAccuracy;
@synthesize locationAccurateDistanceFilter = _locationAccurateDistanceFilter;
@synthesize locationPausesLocationUpdatesAutomatically = _locationPausesLocationUpdatesAutomatically;
@synthesize ASATokenFirstDelay = _ASATokenFirstDelay;
@synthesize ASATokenReportingInterval = _ASATokenReportingInterval;
@synthesize ASATokenEndReportingInterval = _ASATokenEndReportingInterval;
@synthesize attributionDeeplinkConditions = _attributionDeeplinkConditions;
@synthesize externalAttributionCollectingInterval = _externalAttributionCollectingInterval;
@synthesize appleTrackingHosts = _appleTrackingHosts;
@synthesize applePrivacyResendPeriod = _applePrivacyResendPeriod;
@synthesize applePrivacyRetryPeriod = _applePrivacyRetryPeriod;
@synthesize extendedParameters = _extendedParameters;
@synthesize storage = _storage;

- (instancetype)init
{
    self = [super initWithStorage:nil];
    if (self != nil) {
        
    }
    return self;
}

@end
