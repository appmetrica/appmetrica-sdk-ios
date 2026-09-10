#import "AMAAppMetricaConfigurationProviderMock.h"
#import "AMAAppMetricaConfigurationSnapshot.h"

@implementation AMAAppMetricaConfigurationProviderMock

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshot
{
    [self.loadSnapshotExpectation fulfill];
    if (self.configuration == nil && self.savedAt == nil) {
        return nil;
    }
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:self.configuration
                                                                     savedAt:self.savedAt
                                                                      source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
}

- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    [self.saveSnapshotExpectation fulfill];
    self.configuration = snapshot.configuration;
    self.savedAt = snapshot.savedAt;
}

- (void)clearSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    self.configuration = nil;
    self.savedAt = nil;
}

@end
