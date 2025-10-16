
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

@class AMAIDSyncStartupConfiguration;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncStartupController : NSObject<AMAReporterStorageControlling, AMAExtendedStartupObserving>

@property (nonatomic, strong, readonly) AMAIDSyncStartupConfiguration *startup;

+ (instancetype)sharedInstance;

- (id<AMAKeyValueStoring>)storage;
- (void)saveStorage;

@end

NS_ASSUME_NONNULL_END
