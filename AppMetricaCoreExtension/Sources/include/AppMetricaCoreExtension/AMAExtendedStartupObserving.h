
#import <Foundation/Foundation.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAStartupStorageProviding <NSObject>

- (id<AMAKeyValueStoring>)startupStorageForKeys:(NSArray<NSString *> *)keys;
- (void)saveStorage:(id<AMAKeyValueStoring>)storage;

@end

@protocol AMACachingStorageProviding <NSObject>

- (id<AMAKeyValueStoring>)cachingStorage;

@end

@protocol AMAExtendedStartupObserving <NSObject>

- (NSDictionary *)startupParameters;

- (void)startupUpdatedWithParameters:(NSDictionary *)parameters;

- (void)setupStartupProvider:(id<AMAStartupStorageProviding>)startupStorageProvider
      cachingStorageProvider:(id<AMACachingStorageProviding>)cachingStorageProvider;

@end

NS_ASSUME_NONNULL_END
