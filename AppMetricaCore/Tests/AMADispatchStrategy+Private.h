
#import "AMADispatchStrategy.h"

@protocol AMAAsyncExecuting;

@interface AMADispatchStrategy ()

@property (nonatomic, strong) id<AMAAsyncExecuting> executor;
@property (nonatomic, weak) id<AMADispatchStrategyDelegate> delegate;
@property (nonatomic, strong) AMAReporterStorage *storage;

@end
