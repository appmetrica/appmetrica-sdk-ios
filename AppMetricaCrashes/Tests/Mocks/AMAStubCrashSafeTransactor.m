
#import "AMAStubCrashSafeTransactor.h"

@implementation AMAStubCrashSafeTransactor

- (instancetype)initWithReporter:(id<AMATransactionReporting>)reporter
{
    return [super initWithReporter:reporter];
}

- (void)processTransactionWithID:(NSString *)transactionID
                            name:(NSString *)name
                     transaction:(dispatch_block_t)transaction
{
    if (transaction != nil) {
        transaction();
    }
}

- (void)processTransactionWithID:(NSString *)transactionID
                            name:(NSString *)name
                     transaction:(dispatch_block_t)transaction
                        rollback:(AMACrashSafeTransactorRollbackBlock)rollback
{
    if (transaction != nil) {
        transaction();
    }
}

@end
