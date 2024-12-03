
#import <Foundation/Foundation.h>
#import <AppMetricaCoreUtils/AppMetricaCoreUtils.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kAMAKeychainErrorDomain;
extern NSString *const kAMAKeychainErrorKeyCode;

typedef NS_ERROR_ENUM(kAMAKeychainErrorDomain, AMAKeychainErrorCode) {
    AMAKeychainErrorCodeGeneral,
    AMAKeychainErrorCodeQueryCreation,
    AMAKeychainErrorCodeDecode,
    AMAKeychainErrorCodeDuplicate,
    AMAKeychainErrorCodeLocked,
    AMAKeychainErrorCodeInvalidType
} NS_SWIFT_NAME(KeychainError);

NS_SWIFT_NAME(KeychainStoring)
@protocol AMAKeychainStoring <NSObject>

- (BOOL)addStringValue:(NSString *)value forKey:(NSString *)key error:(NSError * _Nullable *)error NS_SWIFT_NAME(addStringValue(_:for:));
- (BOOL)setStringValue:(NSString *)value forKey:(NSString *)key error:(NSError * _Nullable *)error NS_SWIFT_NAME(setStringValue(_:for:));
- (BOOL)removeStringValueForKey:(NSString *)key error:(NSError * _Nullable *)error NS_SWIFT_NAME(removeStringValue(for:));
- (nullable NSString *)stringValueForKey:(NSString *)key error:(NSError * _Nullable *)error NS_SWIFT_NAME(stringValue(for:)) AMA_SWIFT_ERROR_NULLABLE;

@end

NS_ASSUME_NONNULL_END
