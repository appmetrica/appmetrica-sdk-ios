
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeyValueStorageDataProviding)
@protocol AMAKeyValueStorageDataProviding <NSObject>

- (nullable NSArray<NSString *> *)allKeysWithError:(NSError * __autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable id)objectForKey:(NSString *)key error:(NSError * __autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (BOOL)removeKey:(NSString *)key error:(NSError * __autoreleasing _Nullable *)error;
- (BOOL)saveObject:(nullable id)object forKey:(NSString *)key error:( NSError * __autoreleasing _Nullable *)error;

- (nullable NSDictionary<NSString *, id> *)objectsForKeys:(NSArray *)keys error:(NSError * __autoreleasing _Nullable*)error;
- (BOOL)saveObjectsDictionary:(NSDictionary<NSString *, id> *)objectsDictionary error:(NSError * __autoreleasing _Nullable*)error;

@end

NS_ASSUME_NONNULL_END
