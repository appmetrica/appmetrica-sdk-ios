
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AMADispatchQueueWaitResult) {
    AMADispatchQueueWaitResultOk,
    AMADispatchQueueWaitResultTimeout,
};

@interface AMADispatchQueueTestHelper : NSObject

+ (AMADispatchQueueWaitResult)waitQueue:(dispatch_queue_t)queue;
+ (BOOL)isQueueLockedNow:(dispatch_queue_t)queue;
+ (BOOL)isQueueSerial:(dispatch_queue_t)queue;

@end
