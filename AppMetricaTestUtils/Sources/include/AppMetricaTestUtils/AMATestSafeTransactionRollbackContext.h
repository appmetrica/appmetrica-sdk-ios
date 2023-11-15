
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(TestSafeTransactionRollbackContext)
@interface AMATestSafeTransactionRollbackContext : NSObject <NSCoding>

@property (nonatomic, strong, readonly) NSString *param1;
@property (nonatomic, strong, readonly) NSString *param2;

@end

NS_ASSUME_NONNULL_END
