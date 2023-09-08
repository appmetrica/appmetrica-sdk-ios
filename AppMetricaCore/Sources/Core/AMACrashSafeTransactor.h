
#import <Foundation/Foundation.h>

typedef NSString * (^AMACrashSafeTransactorRollbackBlock)(id context);

@interface AMACrashSafeTransactor : NSObject

+ (void)processTransactionWithID:(NSString *)transactionID
                            name:(NSString *)name
                     transaction:(dispatch_block_t)transaction;

+ (void)processTransactionWithID:(NSString *)transactionID
                            name:(NSString *)name
                     transaction:(dispatch_block_t)transaction
                        rollback:(AMACrashSafeTransactorRollbackBlock)rollback;

+ (void)processTransactionWithID:(NSString *)transactionID
                            name:(NSString *)name
                 rollbackContext:(id<NSCoding>)rollBackContext
                     transaction:(dispatch_block_t)transaction
                        rollback:(AMACrashSafeTransactorRollbackBlock)rollback;
                 

@end
