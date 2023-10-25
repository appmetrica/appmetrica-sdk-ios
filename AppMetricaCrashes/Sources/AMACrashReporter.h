#import <Foundation/Foundation.h>

#import "AMACrashSafeTransactor.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AMACrashProcessingReporting;
@class AMACustomEventParameters;

@interface AMACrashReporter : NSObject <AMATransactionReporter>

@property (nonatomic, strong) NSMutableSet<id<AMACrashProcessingReporting>> *extendedCrashReporters; // FIXME: (glinnik, belanovich-sy) needed any more?

- (instancetype)initWithReporter:(id<AMAAppMetricaReporting>)reporter NS_DESIGNATED_INITIALIZER;

- (void)reportCrashWithParameters:(AMACustomEventParameters *)parameters;
- (void)reportANRWithParameters:(AMACustomEventParameters *)parameters;
- (void)reportErrorWithParameters:(AMACustomEventParameters *)parameters
                        onFailure:(nullable void (^)(NSError *))onFailure;

- (void)reportInternalError:(NSError *)error;
- (void)reportInternalCorruptedCrash:(NSError *)error;
- (void)reportInternalCorruptedError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
