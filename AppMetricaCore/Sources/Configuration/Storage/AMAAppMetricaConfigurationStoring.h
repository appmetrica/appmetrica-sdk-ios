#import <Foundation/Foundation.h>
#import "AMAAppMetricaConfigurationSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

@class AMAAppMetricaConfigurationSnapshot;

typedef AMAAppMetricaConfigurationSnapshot * _Nullable
    (^AMAConfigurationSnapshotUpdate)(AMAAppMetricaConfigurationSnapshot *current);

typedef AMAAppMetricaConfigurationSnapshot * _Nullable
    (^AMAConfigurationSnapshotBuilder)(AMAAppMetricaConfigurationSnapshot * _Nullable current);

/// Single-file backend (private or group). Implemented by FileStorage.
@protocol AMAAppMetricaConfigurationFileStoring <NSObject>
- (nullable AMAAppMetricaConfigurationSnapshot *)loadSnapshot;
- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot;
- (void)deleteSnapshot;
@end

/// High-level storage (Coordinator). Save and atomic update under one exclusive lock.
@protocol AMAAppMetricaConfigurationStoring <NSObject>
- (void)saveSnapshot:(AMAAppMetricaConfigurationSnapshot *)snapshot;
- (BOOL)updateLoadedSnapshot:(AMAConfigurationSnapshotUpdate)update
                      result:(AMAAppMetricaConfigurationSnapshot * _Nullable * _Nullable)result;
- (void)saveSnapshotUsingCurrent:(AMAConfigurationSnapshotBuilder)builder;
@end

NS_ASSUME_NONNULL_END
