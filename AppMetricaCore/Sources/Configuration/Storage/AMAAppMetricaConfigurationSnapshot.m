#import "AMAAppMetricaConfigurationSnapshot.h"
#import "AMAAppMetricaConfiguration+Internal.h"

@implementation AMAAppMetricaConfigurationSnapshot

- (instancetype)initWithConfiguration:(AMAAppMetricaConfiguration *)configuration
                              savedAt:(NSDate *)savedAt
                               source:(AMAAppMetricaConfigurationSnapshotSource)source
{
    self = [super init];
    if (self != nil) {
        // Prefer an immutable copy; fall back to the original if copy is unavailable (e.g. test mocks).
        _configuration = configuration == nil ? nil : ([configuration copy] ?: configuration);
        _savedAt = savedAt;
        _source = source;
    }
    return self;
}

- (instancetype)snapshotByUpdatingConfiguration:(AMAAppMetricaConfiguration *)configuration
{
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:configuration
                                                                     savedAt:self.savedAt
                                                                      source:self.source];
}

- (instancetype)snapshotByUpdatingSavedAt:(NSDate *)savedAt
{
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:self.configuration
                                                                     savedAt:savedAt
                                                                      source:self.source];
}

- (BOOL)isEqualToSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    if (snapshot == nil) {
        return NO;
    }
    BOOL configurationEqual = (self.configuration == nil && snapshot.configuration == nil)
        || [self.configuration isEqualToConfiguration:snapshot.configuration];
    BOOL savedAtEqual = (self.savedAt == nil && snapshot.savedAt == nil)
        || [self.savedAt isEqualToDate:snapshot.savedAt];
    return configurationEqual && savedAtEqual;
}

@end
