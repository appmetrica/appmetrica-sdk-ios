#import "AMAAppMetricaConfigurationStorageCoordinator.h"
#import "AMAAppMetricaConfigurationSnapshot.h"
#import <AppMetricaPlatform/AppMetricaPlatform.h>

@import AppMetricaSynchronization;

@interface AMAAppMetricaConfigurationStorageCoordinator ()
@property (nonatomic, strong, readonly) id<AMAAppMetricaConfigurationFileStoring> privateStorage;
@property (nonatomic, strong, readonly, nullable) id<AMAAppMetricaConfigurationFileStoring> groupStorage;
@property (nonatomic, strong, readonly) id<AMAExclusiveLocking> lock;
@end

@implementation AMAAppMetricaConfigurationStorageCoordinator

- (instancetype)initWithPrivateStorage:(id<AMAAppMetricaConfigurationFileStoring>)privateStorage
                          groupStorage:(id<AMAAppMetricaConfigurationFileStoring>)groupStorage
                                  lock:(id<AMAExclusiveLocking>)lock
{
    NSParameterAssert(privateStorage != nil);
    NSParameterAssert(lock != nil);
    self = [super init];
    if (self) {
        _privateStorage = privateStorage;
        _groupStorage = groupStorage;
        _lock = lock;
    }
    return self;
}

- (AMAAppMetricaConfigurationSnapshot *)copySnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    if (snapshot == nil) {
        return nil;
    }
    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:snapshot.configuration
                                                                     savedAt:snapshot.savedAt
                                                                      source:snapshot.source];
}

- (id<AMAAppMetricaConfigurationFileStoring>)storageForSource:(AMAAppMetricaConfigurationSnapshotSource)source
{
    if (source == AMAAppMetricaConfigurationSnapshotSourcePrivate) {
        return self.privateStorage;
    }
    if (source == AMAAppMetricaConfigurationSnapshotSourceGroup && self.groupStorage != nil) {
        return self.groupStorage;
    }
    return nil;
}

- (AMAAppMetricaConfigurationSnapshot *)loadSnapshotUnlocked
{
    AMAAppMetricaConfigurationSnapshot *snapshot = [self.privateStorage loadSnapshot];
    AMAAppMetricaConfigurationSnapshotSource source = AMAAppMetricaConfigurationSnapshotSourcePrivate;

    if (snapshot == nil && self.groupStorage != nil) {
        snapshot = [self.groupStorage loadSnapshot];
        source = AMAAppMetricaConfigurationSnapshotSourceGroup;
    }

    if (snapshot == nil || snapshot.configuration == nil) {
        return nil;
    }

    return [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:snapshot.configuration
                                                                     savedAt:snapshot.savedAt
                                                                      source:source];
}

- (void)saveSnapshotUnlocked:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    if (snapshot.configuration == nil) {
        return;
    }

    id<AMAAppMetricaConfigurationFileStoring> storage = [self storageForSource:snapshot.source];
    if (storage == nil) {
        return;
    }
    [storage saveSnapshot:snapshot];

    BOOL mirrorToGroup =
        snapshot.source == AMAAppMetricaConfigurationSnapshotSourcePrivate &&
        [AMAPlatformDescription runEnvronment] == AMARunEnvironmentMainApp &&
        self.groupStorage != nil;
    if (mirrorToGroup) {
        [self.groupStorage saveSnapshot:snapshot];
    }
}

- (void)clearSnapshotUnlocked:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    id<AMAAppMetricaConfigurationFileStoring> storage = [self storageForSource:snapshot.source];
    [storage deleteSnapshot];
}

- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot
{
    AMAAppMetricaConfigurationSnapshot *toSave = [self copySnapshot:snapshot];
    if (![self.lock performWithExclusiveLock:^{
        [self saveSnapshotUnlocked:toSave];
    }]) {
        return;
    }
}

- (BOOL)updateLoadedSnapshot:(AMAConfigurationSnapshotUpdate)update
                      result:(AMAAppMetricaConfigurationSnapshot **)result
{
    NSParameterAssert(update != nil);
    if (result != NULL) {
        *result = nil;
    }

    __block AMAAppMetricaConfigurationSnapshot *resultSnapshot = nil;
    BOOL locked = [self.lock performWithExclusiveLock:^{
        AMAAppMetricaConfigurationSnapshot *current = [self loadSnapshotUnlocked];
        if (current == nil) {
            return;
        }

        AMAAppMetricaConfigurationSnapshot *original = [self copySnapshot:current];
        AMAAppMetricaConfigurationSnapshot *updated = update(current);

        if (updated == nil) {
            [self clearSnapshotUnlocked:original];
            return;
        }

        if (updated.configuration == nil || updated.source != original.source) {
            return;
        }

        AMAAppMetricaConfigurationSnapshot *toSave = [self copySnapshot:updated];
        if ([original isEqualToSnapshot:toSave] == NO) {
            [self saveSnapshotUnlocked:toSave];
        }
        resultSnapshot = toSave;
    }];

    if (result != NULL) {
        *result = resultSnapshot;
    }
    return locked;
}

- (void)saveSnapshotUsingCurrent:(AMAConfigurationSnapshotBuilder)builder
{
    NSParameterAssert(builder != nil);
    if (![self.lock performWithExclusiveLock:^{
        AMAAppMetricaConfigurationSnapshot *current = [self loadSnapshotUnlocked];
        AMAAppMetricaConfigurationSnapshot *updated = builder(current);
        if (updated.configuration == nil) {
            return;
        }
        AMAAppMetricaConfigurationSnapshot *toSave =
            [[AMAAppMetricaConfigurationSnapshot alloc] initWithConfiguration:updated.configuration
                                                                      savedAt:updated.savedAt
                                                                       source:AMAAppMetricaConfigurationSnapshotSourcePrivate];
        [self saveSnapshotUnlocked:toSave];
    }]) {
        return;
    }
}

@end
