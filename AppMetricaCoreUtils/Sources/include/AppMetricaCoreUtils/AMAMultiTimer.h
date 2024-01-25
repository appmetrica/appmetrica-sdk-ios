
#import <Foundation/Foundation.h>

@class AMAMultiTimer;
@protocol AMACancelableExecuting;

typedef NS_ENUM(NSInteger, AMAMultitimerStatus) {
    AMAMultitimerStatusNotStarted,
    AMAMultitimerStatusStarted,
};

NS_ASSUME_NONNULL_BEGIN

@protocol AMAMultitimerDelegate <NSObject>
- (void)multitimerDidFire:(AMAMultiTimer *)multitimer;
@end

@interface AMAMultiTimer : NSObject

@property (nonatomic, weak) id<AMAMultitimerDelegate> delegate;
@property (nonatomic) AMAMultitimerStatus status;

- (instancetype)initWithDelays:(NSArray<NSNumber *> *)delays
                      executor:(id<AMACancelableExecuting>)executor
                      delegate:(nullable id<AMAMultitimerDelegate>)delegate;

- (void)start;
- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
