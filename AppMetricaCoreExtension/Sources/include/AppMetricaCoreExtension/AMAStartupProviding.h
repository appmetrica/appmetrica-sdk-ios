
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAStartupStorageProviding <NSObject>

- (id<AMAKeyValueStoring>)startupStorageForKeys:(NSArray<NSString *> *)keys;
- (void)saveStorage:(id<AMAKeyValueStoring>)storage;

@end

@protocol AMACachingStorageProviding <NSObject>

- (id<AMAKeyValueStoring>)cachingStorage;

@end

@protocol AMAStartupProviding <NSObject>

- (NSDictionary *)startupRequestParameters;

- (void)startupUpdatedWithAdditionalParameters:(NSDictionary *)parameters
                        startupStorageProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
                        cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider;
@end

NS_ASSUME_NONNULL_END
