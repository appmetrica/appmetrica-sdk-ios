
#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMATestStartupStorageProvider : NSObject <AMAStartupStorageProviding>
@property (nonatomic, strong, nullable) id<AMAKeyValueStoring> storage;
@property (nonatomic, strong, readonly) NSMutableArray<id<AMAKeyValueStoring>> *savedStorages;
@end

@interface AMATestCachingStorageProvider : NSObject <AMACachingStorageProviding>
@end

NS_ASSUME_NONNULL_END
