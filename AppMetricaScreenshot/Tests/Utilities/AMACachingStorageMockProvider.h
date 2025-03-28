#import <Foundation/Foundation.h>
#import <AppMetricaCoreExtension/AppMetricaCoreExtension.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMACachingStorageMockProvider : NSObject<AMACachingStorageProviding>

@property (nonatomic, strong) id<AMAKeyValueStoring> mockedCachingStorage;

@end

NS_ASSUME_NONNULL_END
