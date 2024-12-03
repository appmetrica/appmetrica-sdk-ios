#import "AMAMetricaPersistentConfigurationMock.h"

@implementation AMAMetricaPersistentConfigurationMock

@synthesize hadFirstStartup = _hadFirstStartup;
@synthesize startupUpdatedAt = _startupUpdatedAt;
@synthesize firstStartupUpdateDate = _firstStartupUpdateDate;
@synthesize userStartupHosts = _userStartupHosts;
@synthesize deviceID = _deviceID;
@synthesize deviceIDHash = _deviceIDHash;
@synthesize attributionModelConfiguration = _attributionModelConfiguration;
@synthesize externalAttributionConfigurations = _externalAttributionConfigurations;
@synthesize extensionsLastReportDate = _extensionsLastReportDate;
@synthesize timeoutConfiguration = _timeoutConfiguration;
@synthesize lastPermissionsUpdateDate = _lastPermissionsUpdateDate;
@synthesize registerForAttributionTime = _registerForAttributionTime;
@synthesize conversionValue = _conversionValue;
@synthesize checkedInitialAttribution = _checkedInitialAttribution;
@synthesize eventCountsByKey = _eventCountsByKey;
@synthesize eventSum = _eventSum;
@synthesize revenueTransactionIds = _revenueTransactionIds;

- (instancetype)init 
{
    self = [super initWithStorage:nil identifierManager:nil inMemoryConfiguration:nil];
    if (self != nil) {
        
    }
    return self;
}

@end
