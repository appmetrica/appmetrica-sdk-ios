
#import <Foundation/Foundation.h>

@class AMAIDSyncRequest;
@protocol AMAAppMetricaReporting;

NS_ASSUME_NONNULL_BEGIN

@interface AMAIDSyncReporter : NSObject

- (instancetype)initWithReporter:(nullable id<AMAAppMetricaReporting>)libraryReporter;

- (void)reportEventForRequest:(AMAIDSyncRequest *)request
                         code:(NSInteger)code
                         body:(NSString *)body
                      headers:(NSDictionary<NSString *, NSArray<NSString *> *> *)headers
                  responseURL:(NSString *)responseURL;

@end

NS_ASSUME_NONNULL_END
