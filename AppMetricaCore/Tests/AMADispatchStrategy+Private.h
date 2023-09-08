
#import "AMADispatchStrategy.h"

@protocol AMAExecuting;

@interface AMADispatchStrategy ()

@property (nonatomic, strong) id<AMAExecuting> executor;
@property (nonatomic, weak) id<AMADispatchStrategyDelegate> delegate;
@property (nonatomic, strong) AMAReporterStorage *storage;

@end
