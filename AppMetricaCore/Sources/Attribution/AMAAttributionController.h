
#import <Foundation/Foundation.h>

@class AMAReporter;
@class AMAAttributionModelConfiguration;
@protocol AMAAsyncExecuting;

@interface AMAAttributionController : NSObject

@property (nonatomic, strong, readwrite) AMAAttributionModelConfiguration *config;
@property (nonatomic, strong, readwrite) AMAReporter *mainReporter;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor;
- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor
                           config:(AMAAttributionModelConfiguration *)config;

@end
