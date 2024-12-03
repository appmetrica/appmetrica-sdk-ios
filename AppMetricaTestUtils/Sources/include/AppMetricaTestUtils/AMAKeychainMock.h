
#import <Foundation/Foundation.h>
#import <AppMetricaKeychain/AppMetricaKeychain.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(KeychainMock)
@interface AMAKeychainMock : NSObject<AMAKeychainStoring>

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSString *> *storage;
@property (nonatomic) BOOL isLocked;

@end

NS_ASSUME_NONNULL_END
