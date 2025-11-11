
#import <AppMetricaKiwi/AppMetricaKiwi.h>
#import <AppMetricaStorageUtils/AppMetricaStorageUtils.h>

SPEC_BEGIN(AMARollbackHolderTests)

describe(@"AMARollbackHolder", ^{

    BOOL __block blockCalled = NO;
    AMARollbackHolder *__block holder = nil;

    beforeEach(^{
        blockCalled = NO;
        holder = [[AMARollbackHolder alloc] init];
    });

    void (^defaultCallback)(void) = ^{
        blockCalled = YES;
    };

    it(@"Should not call callback if no rollback", ^{
        [holder subscribeOnRollback:defaultCallback];
        [holder complete];
        [[theValue(blockCalled) should] beNo];
    });
    it(@"Should call callback if rollback", ^{
        [holder subscribeOnRollback:defaultCallback];
        holder.rollback = YES;
        [holder complete];
        [[theValue(blockCalled) should] beYes];
    });
    it(@"Should call blocks in reverse order", ^{
        NSMutableArray *order = [NSMutableArray array];
        [holder subscribeOnRollback:^{
            [order addObject:@1];
        }];
        [holder subscribeOnRollback:^{
            [order addObject:@2];
        }];
        [holder subscribeOnRollback:^{
            [order addObject:@3];
        }];
        holder.rollback = YES;
        [holder complete];
        [[order should] equal:@[ @3, @2, @1 ]];
    });
    it(@"Should not raise for nil block", ^{
        dispatch_block_t block = nil;
        [[theBlock(^{
            [holder subscribeOnRollback:block];
        }) shouldNot] raise];
    });

});

SPEC_END

