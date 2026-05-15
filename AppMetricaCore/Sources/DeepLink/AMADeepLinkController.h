
#import <Foundation/Foundation.h>

@protocol AMAAsyncExecuting;
@class AMAReporter;

extern NSString *const kAMADLControllerUrlTypeOpen;

@interface AMADeepLinkController : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithExecutor:(id<AMAAsyncExecuting>)executor NS_DESIGNATED_INITIALIZER;

- (void)reportUrl:(NSURL *)url ofType:(NSString *)type isAuto:(BOOL)isAuto;
- (void)updateReporter:(AMAReporter *)reporter;

@end
