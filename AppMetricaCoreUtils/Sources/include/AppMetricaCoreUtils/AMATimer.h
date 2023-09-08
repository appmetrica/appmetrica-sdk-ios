
#import <Foundation/Foundation.h>

@class AMATimer;

@protocol AMATimerDelegate <NSObject>
- (void)timerDidFire:(AMATimer *)timer;
@end

@interface AMATimer : NSObject

@property (nonatomic, strong, readonly) NSDate *startDate;

@property (nonatomic, weak) id<AMATimerDelegate> delegate;
 
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (id)initWithTimeout:(NSTimeInterval)timeout;
- (id)initWithTimeout:(NSTimeInterval)timeout callbackQueue:(dispatch_queue_t)queue;
- (void)start;
- (void)invalidate;

@end
