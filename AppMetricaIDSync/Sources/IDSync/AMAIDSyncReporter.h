
#import <Foundation/Foundation.h>

@class AMAIDSyncRequestResponse;
@protocol AMAAppMetricaReporting;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncReporter : NSObject

- (instancetype)initWithReporter:(nullable id<AMAAppMetricaReporting>)libraryReporter;

- (void)reportEventForResponse:(AMAIDSyncRequestResponse *)response;

@end

NS_ASSUME_NONNULL_END
