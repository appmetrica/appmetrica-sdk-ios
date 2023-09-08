
#import "AMADispatchQueueTestHelper.h"

static NSTimeInterval const kAMADispatchQueueTestHelperDefaultTimeout = 1.0;

@implementation AMADispatchQueueTestHelper

+ (AMADispatchQueueWaitResult)waitQueue:(dispatch_queue_t)queue
{
    return [self waitQueue:queue timeout:kAMADispatchQueueTestHelperDefaultTimeout];
}

+ (AMADispatchQueueWaitResult)waitQueue:(dispatch_queue_t)queue timeout:(NSTimeInterval)timeout
{
    AMADispatchQueueWaitResult result = AMADispatchQueueWaitResultOk;
    dispatch_block_t block = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{ });
    dispatch_async(queue, block);
    long status = dispatch_block_wait(block, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)));
    if (status != 0) {
        result = AMADispatchQueueWaitResultTimeout;
    }
    return result;
}

+ (BOOL)isQueueLockedNow:(dispatch_queue_t)queue
{
    return [self isQueueLockedNow:queue timeout:kAMADispatchQueueTestHelperDefaultTimeout];
}

+ (BOOL)isQueueLockedNow:(dispatch_queue_t)queue timeout:(NSTimeInterval)timeout
{
    return [self waitQueue:queue timeout:timeout] == AMADispatchQueueWaitResultTimeout;
}

+ (BOOL)isQueueSerial:(dispatch_queue_t)queue
{
    BOOL __block isSerial = NO;
    dispatch_sync(queue, ^{
        isSerial = [self isQueueLockedNow:queue];
    });
    return isSerial;
}

@end
