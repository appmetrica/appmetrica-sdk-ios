
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AMAKeyValueStoring;

NS_SWIFT_NAME(ReadonlyKeyValueStoring)
@protocol AMAReadonlyKeyValueStoring <NSObject>

- (nullable NSString *)stringForKey:(NSString *)key error:(NSError * __autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSData *)dataForKey:(NSString *)key error:(NSError * __autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSDate *)dateForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSNumber *)boolNumberForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSNumber *)longLongNumberForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSNumber *)unsignedLongLongNumberForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSNumber *)doubleNumberForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSDictionary *)jsonDictionaryForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;
- (nullable NSArray *)jsonArrayForKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error AMA_SWIFT_ERROR_NULLABLE;

@end;

NS_SWIFT_NAME(KeyValueStoring)
@protocol AMAKeyValueStoring <AMAReadonlyKeyValueStoring>

- (BOOL)saveString:(nullable NSString *)string forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveData:(nullable NSData *)data forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveDate:(nullable NSDate *)date forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveBoolNumber:(nullable NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveLongLongNumber:(nullable NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveUnsignedLongLongNumber:(nullable NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveDoubleNumber:(nullable NSNumber *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveJSONDictionary:(nullable NSDictionary *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)saveJSONArray:(nullable NSArray *)value forKey:(NSString *)key error:(NSError *__autoreleasing _Nullable *)error;
- (BOOL)removeValueForKey:(NSString*)key error:(NSError *__autoreleasing _Nullable *)error;

@end;

NS_ASSUME_NONNULL_END
