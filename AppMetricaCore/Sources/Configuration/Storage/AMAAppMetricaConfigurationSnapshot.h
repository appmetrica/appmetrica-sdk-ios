#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AMAAppMetricaConfiguration;

typedef NS_ENUM(NSInteger, AMAAppMetricaConfigurationSnapshotSource) {
    AMAAppMetricaConfigurationSnapshotSourcePrivate = 0,
    AMAAppMetricaConfigurationSnapshotSourceGroup,
};

@interface AMAAppMetricaConfigurationSnapshot : NSObject

@property (nonatomic, strong, nullable, readonly) AMAAppMetricaConfiguration *configuration;
@property (nonatomic, strong, nullable, readonly) NSDate *savedAt;
/// Which storage produced this snapshot on load. Not serialized.
@property (nonatomic, assign, readonly) AMAAppMetricaConfigurationSnapshotSource source;

- (instancetype)initWithConfiguration:(nullable AMAAppMetricaConfiguration *)configuration
                              savedAt:(nullable NSDate *)savedAt
                               source:(AMAAppMetricaConfigurationSnapshotSource)source;

- (instancetype)snapshotByUpdatingConfiguration:(nullable AMAAppMetricaConfiguration *)configuration;
- (instancetype)snapshotByUpdatingSavedAt:(nullable NSDate *)savedAt;

- (BOOL)isEqualToSnapshot:(nullable AMAAppMetricaConfigurationSnapshot *)snapshot;

@end

NS_ASSUME_NONNULL_END
