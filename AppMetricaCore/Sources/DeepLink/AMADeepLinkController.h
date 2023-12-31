
#import <Foundation/Foundation.h>

@protocol AMAExecuting;
@class AMAReporter;

extern NSString *const kAMADLControllerUrlTypeOpen;
extern NSString *const kAMADLControllerUrlTypeReferral;

@interface AMADeepLinkController : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithReporter:(AMAReporter *)reporter
                        executor:(id<AMAExecuting>)executor NS_DESIGNATED_INITIALIZER;

- (void)reportUrl:(NSURL *)url ofType:(NSString *)type isAuto:(BOOL)isAuto;

@end
