
#import <Foundation/Foundation.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>

@class AMAKeychainBridge;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Keychain)
@interface AMAKeychain : NSObject <AMAKeychainStoring>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable instancetype)initWithService:(NSString *)service;
- (nullable instancetype)initWithService:(NSString *)service
                             accessGroup:(NSString *)accessGroup;
- (nullable instancetype)initWithService:(NSString *)service
                             accessGroup:(NSString *)accessGroup
                                  bridge:(AMAKeychainBridge *)bridge NS_DESIGNATED_INITIALIZER;

- (void)resetKeychain;

- (BOOL)isAvailable;

@end

NS_ASSUME_NONNULL_END
